package com.concert.repository;

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
}
