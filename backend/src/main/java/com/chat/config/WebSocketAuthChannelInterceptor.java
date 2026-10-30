package com.chat.config;

import com.chat.repository.ConversationMemberRepository;
import com.chat.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import java.util.UUID;

@Component
public class WebSocketAuthChannelInterceptor implements ChannelInterceptor {

    private static final Logger log = LoggerFactory.getLogger(WebSocketAuthChannelInterceptor.class);

    private final JwtService jwtService;
    private final UserRepository userRepository;
    private final ConversationMemberRepository memberRepository;

    public WebSocketAuthChannelInterceptor(
        JwtService jwtService,
        UserRepository userRepository,
        ConversationMemberRepository memberRepository
    ) {
        this.jwtService = jwtService;
        this.userRepository = userRepository;
        this.memberRepository = memberRepository;
    }

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
        if (accessor == null) {
            return message;
        }

        // 1. Authenticate on STOMP CONNECT frame
        if (StompCommand.CONNECT.equals(accessor.getCommand())) {
            String token = extractToken(accessor);

            if (StringUtils.hasText(token) && jwtService.validateToken(token)) {
                UUID userId = jwtService.extractUserId(token);
                var userOpt = userRepository.findById(userId);

                if (userOpt.isPresent()) {
                    UserPrincipal principal = UserPrincipal.create(userOpt.get());
                    UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(
                        principal,
                        null,
                        principal.getAuthorities()
                    );
                    accessor.setUser(auth);
                    log.info("STOMP connection authenticated for user: {}", principal.getUsername());
                } else {
                    throw new AccessDeniedException("User not found for provided JWT token");
                }
            } else {
                throw new AccessDeniedException("Invalid or missing JWT token on STOMP CONNECT");
            }
        }

        // 2. Authorize on SUBSCRIBE frame to protect conversation topics
        if (StompCommand.SUBSCRIBE.equals(accessor.getCommand())) {
            String destination = accessor.getDestination();
            if (destination != null && destination.startsWith("/topic/conversation.")) {
                if (!(accessor.getUser() instanceof UsernamePasswordAuthenticationToken authToken) ||
                    !(authToken.getPrincipal() instanceof UserPrincipal principal)) {
                    throw new AccessDeniedException("Unauthenticated subscription attempt");
                }

                try {
                    // Extract conversation UUID from /topic/conversation.{id} or /topic/conversation.{id}.typing
                    String rest = destination.substring("/topic/conversation.".length());
                    int dotIndex = rest.indexOf('.');
                    String convIdStr = dotIndex != -1 ? rest.substring(0, dotIndex) : rest;
                    UUID conversationId = UUID.fromString(convIdStr);

                    boolean isMember = memberRepository.existsByConversationIdAndUserId(conversationId, principal.getId());
                    if (!isMember) {
                        log.warn("Subscription denied: User {} is not a member of conversation {}", principal.getUsername(), conversationId);
                        throw new AccessDeniedException("User is not a member of this conversation");
                    }
                    log.debug("User {} authorized to subscribe to {}", principal.getUsername(), destination);
                } catch (IllegalArgumentException e) {
                    log.warn("Invalid conversation ID format in destination: {}", destination);
                }
            } else if (destination != null && destination.startsWith("/topic/user.")) {
                if (!(accessor.getUser() instanceof UsernamePasswordAuthenticationToken authToken) ||
                    !(authToken.getPrincipal() instanceof UserPrincipal principal)) {
                    throw new AccessDeniedException("Unauthenticated subscription attempt");
                }

                try {
                    // Extract user UUID from /topic/user.{id}.conversations
                    String rest = destination.substring("/topic/user.".length());
                    int dotIndex = rest.indexOf('.');
                    String userIdStr = dotIndex != -1 ? rest.substring(0, dotIndex) : rest;
                    UUID targetUserId = UUID.fromString(userIdStr);

                    if (!principal.getId().equals(targetUserId)) {
                        log.warn("Subscription denied: User {} tried to subscribe to user topic for {}",
                            principal.getUsername(), targetUserId);
                        throw new AccessDeniedException("Cannot subscribe to another user's private topic");
                    }
                    log.debug("User {} authorized to subscribe to personal topic {}", principal.getUsername(), destination);
                } catch (IllegalArgumentException e) {
                    log.warn("Invalid user ID in destination: {}", destination);
                }
            }
        }

        return message;
    }

    private String extractToken(StompHeaderAccessor accessor) {
        String authHeader = accessor.getFirstNativeHeader("Authorization");
        if (StringUtils.hasText(authHeader) && authHeader.startsWith("Bearer ")) {
            return authHeader.substring(7);
        }
        // Fallback for STOMP clients that send token in passcode header
        String passcode = accessor.getPasscode();
        if (StringUtils.hasText(passcode)) {
            if (passcode.startsWith("Bearer ")) {
                return passcode.substring(7);
            }
            return passcode;
        }
        // Fallback for custom 'token' header
        String tokenHeader = accessor.getFirstNativeHeader("token");
        if (StringUtils.hasText(tokenHeader)) {
            return tokenHeader;
        }
        return null;
    }
}
