package com.chat.repository;

import com.chat.domain.Conversation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ConversationRepository extends JpaRepository<Conversation, UUID> {

    @Query("""
        SELECT DISTINCT c FROM Conversation c
        JOIN c.members m
        WHERE m.user.id = :userId
        ORDER BY c.updatedAt DESC
    """)
    List<Conversation> findAllByUserIdOrderByUpdatedAtDesc(@Param("userId") UUID userId);

    @Query("""
        SELECT c FROM Conversation c
        JOIN c.members m1
        JOIN c.members m2
        WHERE c.type = com.chat.domain.ConversationType.DIRECT
        AND m1.user.id = :user1Id
        AND m2.user.id = :user2Id
    """)
    Optional<Conversation> findDirectConversationBetweenUsers(@Param("user1Id") UUID user1Id, @Param("user2Id") UUID user2Id);
}
