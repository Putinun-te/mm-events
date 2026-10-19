-- Schema as Hibernate's ddl-auto created it before Flyway (exported with
-- jakarta.persistence.schema-generation from the entities). Used to test that
-- such a database is adopted at version 1 and then migrated.

    create table bookings (
        quantity integer not null,
        total_price float(53) not null,
        booking_date datetime(6) not null,
        created_at datetime(6) not null,
        event_start_date datetime(6),
        id bigint not null auto_increment,
        user_id bigint not null,
        event_id varchar(255) not null,
        event_location varchar(255),
        event_title varchar(255),
        status varchar(255) not null,
        primary key (id)
    ) engine=InnoDB;

    create table events (
        person_limit integer,
        ticket_price float(53),
        created_at datetime(6),
        end_date datetime(6) not null,
        event_id bigint not null auto_increment,
        organizer_id bigint,
        start_date datetime(6) not null,
        updated_at datetime(6),
        user_id bigint not null,
        address varchar(255),
        category varchar(255),
        city varchar(255),
        country varchar(255),
        description text,
        location varchar(255),
        name varchar(255) not null,
        phone varchar(255),
        photo_id varchar(255),
        photo_url varchar(255),
        title varchar(255) not null,
        primary key (event_id)
    ) engine=InnoDB;

    create table notification_preferences (
        email_notifications bit,
        event_reminders bit,
        marketing_emails bit,
        push_notifications bit,
        sms_notifications bit,
        created_at datetime(6),
        id bigint not null auto_increment,
        updated_at datetime(6),
        user_id bigint not null,
        primary key (id)
    ) engine=InnoDB;

    create table notifications (
        is_read bit,
        created_at datetime(6),
        id bigint not null auto_increment,
        updated_at datetime(6),
        user_id bigint not null,
        message TEXT,
        title varchar(255) not null,
        type varchar(255),
        primary key (id)
    ) engine=InnoDB;

    create table users (
        created_at datetime(6),
        updated_at datetime(6),
        user_id bigint not null auto_increment,
        address varchar(255),
        city varchar(255),
        company varchar(255),
        country varchar(255),
        email varchar(255) not null,
        name varchar(255) not null,
        password varchar(255) not null,
        phone varchar(255),
        pincode varchar(255),
        profile_photo varchar(255),
        username varchar(255),
        website varchar(255),
        primary key (user_id)
    ) engine=InnoDB;

    alter table notification_preferences 
       add constraint UKn2jopkbm16qv3xelbvoyjkd0g unique (user_id);

    alter table users 
       add constraint UK6dotkott2kjsp8vw4d0m25fb7 unique (email);

    alter table users 
       add constraint UKr43af9ap4edm43mmtq01oddj6 unique (username);

    alter table bookings 
       add constraint FKeyog2oic85xg7hsu2je2lx3s6 
       foreign key (user_id) 
       references users (user_id);

    alter table events 
       add constraint FKat8p3s7yjcp57lny4udqvqncq 
       foreign key (user_id) 
       references users (user_id);
