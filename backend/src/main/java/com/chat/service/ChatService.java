package com.chat.service;

import com.chat.domain.*;
import com.chat.dto.chat.*;
import com.chat.exception.BadRequestException;
import com.chat.exception.ForbiddenException;
import com.chat.exception.ResourceNotFoundException;
import com.chat.repository.*;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class ChatService {

    private final ConversationRepository conversationRepository;
    private final ConversationMemberRepository memberRepository;
    private final MessageRepository messageRepository;
    private final UserRepository userRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public ChatService(
        ConversationRepository conversationRepository,
        ConversationMemberRepository memberRepository,
        MessageRepository messageRepository,
        UserRepository userRepository,
        SimpMessagingTemplate messagingTemplate
    ) {
        this.conversationRepository = conversationRepository;
        this.memberRepository = memberRepository;
        this.messageRepository = messageRepository;
        this.userRepository = userRepository;
        this.messagingTemplate = messagingTemplate;
    }

    @Transactional
    public ConversationDto createOrGetDirectConversation(UUID currentUserId, UUID targetUserId) {
        if (currentUserId.equals(targetUserId)) {
            throw new BadRequestException("Cannot create a direct conversation with yourself");
        }

        User currentUser = userRepository.findById(currentUserId)
            .orElseThrow(() -> new ResourceNotFoundException("Current user not found"));
        User targetUser = userRepository.findById(targetUserId)
            .orElseThrow(() -> new ResourceNotFoundException("Target user not found"));

        // Check if existing direct conversation exists
        Optional<Conversation> existingOpt = conversationRepository.findDirectConversationBetweenUsers(currentUserId, targetUserId);
        if (existingOpt.isPresent()) {
            return ConversationDto.fromEntity(existingOpt.get(), currentUserId);
        }

        // Create new direct conversation
        Conversation conversation = new Conversation(ConversationType.DIRECT, null, currentUser);
        Conversation savedConv = conversationRepository.save(conversation);

        ConversationMember member1 = new ConversationMember(savedConv, currentUser, MemberRole.MEMBER);
        ConversationMember member2 = new ConversationMember(savedConv, targetUser, MemberRole.MEMBER);

        memberRepository.save(member1);
        memberRepository.save(member2);

        savedConv.getMembers().add(member1);
        savedConv.getMembers().add(member2);

        ConversationDto dtoUser1 = ConversationDto.fromEntity(savedConv, currentUserId);
        ConversationDto dtoUser2 = ConversationDto.fromEntity(savedConv, targetUser.getId());

        messagingTemplate.convertAndSend("/topic/user." + currentUserId + ".conversations", dtoUser1);
        messagingTemplate.convertAndSend("/topic/user." + targetUser.getId() + ".conversations", dtoUser2);

        return dtoUser1;
    }

    @Transactional
    public ConversationDto createGroupConversation(UUID creatorId, CreateGroupConversationRequest request) {
        User creator = userRepository.findById(creatorId)
            .orElseThrow(() -> new ResourceNotFoundException("Creator user not found"));

        Conversation conversation = new Conversation(ConversationType.GROUP, request.getTitle().trim(), creator);
        Conversation savedConv = conversationRepository.save(conversation);

        // Add creator as ADMIN
        ConversationMember creatorMember = new ConversationMember(savedConv, creator, MemberRole.ADMIN);
        memberRepository.save(creatorMember);
        savedConv.getMembers().add(creatorMember);

        // Add selected members as MEMBER
        Set<UUID> memberIds = new HashSet<>(request.getMemberUserIds());
        memberIds.remove(creatorId); // Ensure creator isn't added twice

        List<User> members = userRepository.findAllById(memberIds);
        for (User user : members) {
            ConversationMember member = new ConversationMember(savedConv, user, MemberRole.MEMBER);
            memberRepository.save(member);
            savedConv.getMembers().add(member);
        }

        ConversationDto creatorDto = ConversationDto.fromEntity(savedConv, creatorId);
        for (ConversationMember member : savedConv.getMembers()) {
            ConversationDto memberDto = ConversationDto.fromEntity(savedConv, member.getUser().getId());
            messagingTemplate.convertAndSend("/topic/user." + member.getUser().getId() + ".conversations", memberDto);
        }

        return creatorDto;
    }

    @Transactional(readOnly = true)
    public List<ConversationDto> getUserConversations(UUID currentUserId) {
        List<Conversation> conversations = conversationRepository.findAllByUserIdOrderByUpdatedAtDesc(currentUserId);
        return conversations.stream()
            .map(c -> ConversationDto.fromEntity(c, currentUserId))
            .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public ConversationDto getConversationById(UUID conversationId, UUID currentUserId) {
        validateMembership(conversationId, currentUserId);

        Conversation conversation = conversationRepository.findById(conversationId)
            .orElseThrow(() -> new ResourceNotFoundException("Conversation not found"));

        return ConversationDto.fromEntity(conversation, currentUserId);
    }

    @Transactional(readOnly = true)
    public Page<MessageDto> getChatHistory(UUID conversationId, UUID currentUserId, Pageable pageable) {
        validateMembership(conversationId, currentUserId);

        Page<Message> messages = messageRepository.findVisibleMessagesByConversationId(conversationId, currentUserId, pageable);
        return messages.map(MessageDto::fromEntity);
    }

    @Transactional
    public MessageDto saveAndProcessMessage(UUID senderId, SendMessageRequest request) {
        validateMembership(request.getConversationId(), senderId);

        Conversation conversation = conversationRepository.findById(request.getConversationId())
            .orElseThrow(() -> new ResourceNotFoundException("Conversation not found"));

        User sender = userRepository.findById(senderId)
            .orElseThrow(() -> new ResourceNotFoundException("Sender user not found"));

        Message message = new Message(
            conversation,
            sender,
            request.getContent(),
            request.getType() != null ? request.getType() : MessageType.CHAT
        );

        Message savedMessage = messageRepository.save(message);

        // Update conversation's last message and updatedAt timestamp
        conversation.setLastMessage(savedMessage);
        conversation.setUpdatedAt(savedMessage.getSentAt());
        conversationRepository.save(conversation);

        // Broadcast updated conversation state to all members' personal user topics
        for (ConversationMember member : conversation.getMembers()) {
            ConversationDto convDto = ConversationDto.fromEntity(conversation, member.getUser().getId());
            messagingTemplate.convertAndSend("/topic/user." + member.getUser().getId() + ".conversations", convDto);
        }

        return MessageDto.fromEntity(savedMessage);
    }

    public void validateMembership(UUID conversationId, UUID userId) {
        boolean isMember = memberRepository.existsByConversationIdAndUserId(conversationId, userId);
        if (!isMember) {
            throw new ForbiddenException("You are not a member of conversation " + conversationId);
        }
    }

    @Transactional
    public ConversationDto addMembersToGroup(UUID conversationId, UUID requesterId, AddGroupMembersRequest request) {
        Conversation conversation = conversationRepository.findById(conversationId)
            .orElseThrow(() -> new ResourceNotFoundException("Conversation not found"));

        if (conversation.getType() != ConversationType.GROUP) {
            throw new BadRequestException("Cannot add members to a non-group conversation");
        }

        ConversationMember requesterMember = memberRepository.findByConversationIdAndUserId(conversationId, requesterId)
            .orElseThrow(() -> new ForbiddenException("You are not a member of this conversation"));

        if (requesterMember.getRole() != MemberRole.ADMIN) {
            throw new ForbiddenException("Only group admins can add members");
        }

        Set<UUID> toAddIds = new HashSet<>(request.getMemberUserIds());
        for (ConversationMember existing : conversation.getMembers()) {
            toAddIds.remove(existing.getUser().getId());
        }

        if (!toAddIds.isEmpty()) {
            List<User> newUsers = userRepository.findAllById(toAddIds);
            for (User user : newUsers) {
                ConversationMember newMember = new ConversationMember(conversation, user, MemberRole.MEMBER);
                memberRepository.save(newMember);
                conversation.getMembers().add(newMember);
            }
            conversation.setUpdatedAt(Instant.now());
            conversationRepository.save(conversation);
        }

        // Broadcast updated conversation to all members' personal topics
        for (ConversationMember member : conversation.getMembers()) {
            ConversationDto memberDto = ConversationDto.fromEntity(conversation, member.getUser().getId());
            messagingTemplate.convertAndSend("/topic/user." + member.getUser().getId() + ".conversations", memberDto);
        }

        return ConversationDto.fromEntity(conversation, requesterId);
    }

    @Transactional
    public ConversationDto updateMemberRole(UUID conversationId, UUID requesterId, UUID targetUserId, MemberRole newRole) {
        Conversation conversation = conversationRepository.findById(conversationId)
            .orElseThrow(() -> new ResourceNotFoundException("Conversation not found"));

        if (conversation.getType() != ConversationType.GROUP) {
            throw new BadRequestException("Cannot change roles in a non-group conversation");
        }

        ConversationMember requesterMember = memberRepository.findByConversationIdAndUserId(conversationId, requesterId)
            .orElseThrow(() -> new ForbiddenException("You are not a member of this conversation"));

        if (requesterMember.getRole() != MemberRole.ADMIN) {
            throw new ForbiddenException("Only group admins can change member roles");
        }

        ConversationMember targetMember = conversation.getMembers().stream()
            .filter(m -> m.getUser().getId().equals(targetUserId))
            .findFirst()
            .orElseThrow(() -> new ResourceNotFoundException("User is not a member of this conversation"));

        targetMember.setRole(newRole);
        memberRepository.save(targetMember);

        conversation.setUpdatedAt(Instant.now());
        conversationRepository.save(conversation);

        // Broadcast updated conversation to all members
        for (ConversationMember member : conversation.getMembers()) {
            ConversationDto memberDto = ConversationDto.fromEntity(conversation, member.getUser().getId());
            messagingTemplate.convertAndSend("/topic/user." + member.getUser().getId() + ".conversations", memberDto);
        }

        return ConversationDto.fromEntity(conversation, requesterId);
    }

    @Transactional
    public ConversationDto removeMemberFromGroup(UUID conversationId, UUID requesterId, UUID targetUserId) {
        Conversation conversation = conversationRepository.findById(conversationId)
            .orElseThrow(() -> new ResourceNotFoundException("Conversation not found"));

        if (conversation.getType() != ConversationType.GROUP) {
            throw new BadRequestException("Cannot remove members from a non-group conversation");
        }

        ConversationMember requesterMember = memberRepository.findByConversationIdAndUserId(conversationId, requesterId)
            .orElseThrow(() -> new ForbiddenException("You are not a member of this conversation"));

        boolean isSelfLeave = requesterId.equals(targetUserId);
        if (!isSelfLeave && requesterMember.getRole() != MemberRole.ADMIN) {
            throw new ForbiddenException("Only group admins can remove members");
        }

        ConversationMember targetMember = conversation.getMembers().stream()
            .filter(m -> m.getUser().getId().equals(targetUserId))
            .findFirst()
            .orElseThrow(() -> new ResourceNotFoundException("User is not a member of this conversation"));

        memberRepository.delete(targetMember);
        conversation.getMembers().remove(targetMember);

        conversation.setUpdatedAt(Instant.now());
        conversationRepository.save(conversation);

        // Notify remaining members
        for (ConversationMember member : conversation.getMembers()) {
            ConversationDto memberDto = ConversationDto.fromEntity(conversation, member.getUser().getId());
            messagingTemplate.convertAndSend("/topic/user." + member.getUser().getId() + ".conversations", memberDto);
        }

        return ConversationDto.fromEntity(conversation, requesterId);
    }

    @Transactional
    public MessageDto editMessage(UUID conversationId, UUID messageId, UUID requesterId, EditMessageRequest request) {
        validateMembership(conversationId, requesterId);

        Message message = messageRepository.findById(messageId)
            .orElseThrow(() -> new ResourceNotFoundException("Message not found"));

        if (!message.getConversation().getId().equals(conversationId)) {
            throw new BadRequestException("Message does not belong to this conversation");
        }

        if (!message.getSender().getId().equals(requesterId)) {
            throw new ForbiddenException("You can only edit your own messages");
        }

        if (message.isDeletedForEveryone()) {
            throw new BadRequestException("Cannot edit a deleted message");
        }

        message.setContent(request.getContent().trim());
        message.setEdited(true);
        message.setEditedAt(Instant.now());
        Message saved = messageRepository.save(message);

        MessageDto dto = MessageDto.fromEntity(saved);

        // Broadcast real-time message update to conversation topic
        messagingTemplate.convertAndSend("/topic/conversation." + conversationId, dto);

        // If this message was the lastMessage, update conversation preview and broadcast
        Conversation conversation = message.getConversation();
        if (conversation.getLastMessage() != null && conversation.getLastMessage().getId().equals(messageId)) {
            for (ConversationMember member : conversation.getMembers()) {
                ConversationDto convDto = ConversationDto.fromEntity(conversation, member.getUser().getId());
                messagingTemplate.convertAndSend("/topic/user." + member.getUser().getId() + ".conversations", convDto);
            }
        }

        return dto;
    }

    @Transactional
    public MessageDto deleteMessage(UUID conversationId, UUID messageId, UUID requesterId, boolean forEveryone) {
        validateMembership(conversationId, requesterId);

        Message message = messageRepository.findById(messageId)
            .orElseThrow(() -> new ResourceNotFoundException("Message not found"));

        if (!message.getConversation().getId().equals(conversationId)) {
            throw new BadRequestException("Message does not belong to this conversation");
        }

        if (forEveryone) {
            Conversation conversation = message.getConversation();
            boolean isSender = message.getSender().getId().equals(requesterId);
            boolean isGroupAdmin = false;
            if (conversation.getType() == ConversationType.GROUP) {
                ConversationMember requesterMember = memberRepository.findByConversationIdAndUserId(conversationId, requesterId).orElse(null);
                isGroupAdmin = requesterMember != null && requesterMember.getRole() == MemberRole.ADMIN;
            }

            if (!isSender && !isGroupAdmin) {
                throw new ForbiddenException("You do not have permission to delete this message for everyone");
            }

            message.setDeletedForEveryone(true);
            message.setContent("This message was deleted");
            Message saved = messageRepository.save(message);

            MessageDto dto = MessageDto.fromEntity(saved);

            // Broadcast real-time deletion update to conversation topic
            messagingTemplate.convertAndSend("/topic/conversation." + conversationId, dto);

            // Update conversation lastMessage preview
            if (conversation.getLastMessage() != null && conversation.getLastMessage().getId().equals(messageId)) {
                for (ConversationMember member : conversation.getMembers()) {
                    ConversationDto convDto = ConversationDto.fromEntity(conversation, member.getUser().getId());
                    messagingTemplate.convertAndSend("/topic/user." + member.getUser().getId() + ".conversations", convDto);
                }
            }

            return dto;
        } else {
            // Delete for me
            message.getDeletedForUserIds().add(requesterId);
            Message saved = messageRepository.save(message);
            return MessageDto.fromEntity(saved);
        }
    }

    @Transactional
    public void deleteConversation(UUID conversationId, UUID requesterId) {
        Conversation conversation = conversationRepository.findById(conversationId)
            .orElseThrow(() -> new ResourceNotFoundException("Conversation not found"));

        validateMembership(conversationId, requesterId);

        if (conversation.getType() == ConversationType.GROUP) {
            ConversationMember requesterMember = memberRepository.findByConversationIdAndUserId(conversationId, requesterId)
                .orElseThrow(() -> new ForbiddenException("Not a member of this conversation"));

            if (requesterMember.getRole() != MemberRole.ADMIN) {
                // Non-admin leaves the group
                removeMemberFromGroup(conversationId, requesterId, requesterId);
                return;
            }
        }

        // Direct chat or group admin deleting entire chat
        List<UUID> memberUserIds = conversation.getMembers().stream()
            .map(m -> m.getUser().getId())
            .toList();

        conversation.setLastMessage(null);
        conversationRepository.save(conversation);

        messageRepository.deleteAllByConversationId(conversationId);
        memberRepository.deleteAll(conversation.getMembers());
        conversationRepository.delete(conversation);

        // Broadcast deletion event to all participants
        Map<String, Object> deletionEvent = Map.of(
            "id", conversationId.toString(),
            "deleted", true
        );
        for (UUID memberUserId : memberUserIds) {
            messagingTemplate.convertAndSend("/topic/user." + memberUserId + ".conversations", (Object) deletionEvent);
        }
    }
}
