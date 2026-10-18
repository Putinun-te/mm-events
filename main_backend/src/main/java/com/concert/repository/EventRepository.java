package com.concert.repository;

import java.util.Optional;
import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.Lock;
import jakarta.persistence.LockModeType;
import com.concert.model.Event;
import com.concert.model.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface EventRepository extends JpaRepository<Event, Long> {

    Page<Event> findByStartDateAfterOrderByStartDateAsc(LocalDateTime startDate, Pageable pageable);

    Page<Event> findByEndDateAfterOrderByStartDateAsc(LocalDateTime endDate, Pageable pageable);

    List<Event> findByOrganizerOrderByStartDateAsc(User organizer);

    List<Event> findByTitleContaining(String title);

    /** Loads the event and locks its row until the transaction ends (SELECT ... FOR UPDATE). */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select e from Event e where e.id = :id")
    Optional<Event> findByIdForUpdate(@Param("id") Long id);
}
