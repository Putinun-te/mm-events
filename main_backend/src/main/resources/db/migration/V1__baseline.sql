-- Baseline schema: exactly what Hibernate created with ddl-auto=update before Flyway.
-- Databases that already have these tables are baselined at version 1 and skip this
-- script (spring.flyway.baseline-on-migrate=true). Constraint names are Hibernate's,
-- so fresh and baselined databases end up identical.

create table users (
    user_id bigint not null auto_increment,
    name varchar(255) not null,
    username varchar(255),
    email varchar(255) not null,
    password varchar(255) not null,
    profile_photo varchar(255),
    company varchar(255),
    website varchar(255),
    phone varchar(255),
    address varchar(255),
    city varchar(255),
    country varchar(255),
    pincode varchar(255),
    created_at datetime(6),
    updated_at datetime(6),
    primary key (user_id)
) engine=InnoDB;

create table events (
    event_id bigint not null auto_increment,
    title varchar(255) not null,
    name varchar(255) not null,
    description text,
    category varchar(255),
    location varchar(255),
    address varchar(255),
    city varchar(255),
    country varchar(255),
    person_limit integer,
    phone varchar(255),
    start_date datetime(6) not null,
    end_date datetime(6) not null,
    ticket_price float(53),
    photo_id varchar(255),
    photo_url varchar(255),
    user_id bigint not null,
    organizer_id bigint,
    created_at datetime(6),
    updated_at datetime(6),
    primary key (event_id)
) engine=InnoDB;

create table bookings (
    id bigint not null auto_increment,
    user_id bigint not null,
    event_id varchar(255) not null,
    event_title varchar(255),
    event_location varchar(255),
    event_start_date datetime(6),
    quantity integer not null,
    total_price float(53) not null,
    status varchar(255) not null,
    booking_date datetime(6) not null,
    created_at datetime(6) not null,
    primary key (id)
) engine=InnoDB;

create table notifications (
    id bigint not null auto_increment,
    user_id bigint not null,
    title varchar(255) not null,
    message text,
    type varchar(255),
    is_read bit,
    created_at datetime(6),
    updated_at datetime(6),
    primary key (id)
) engine=InnoDB;

create table notification_preferences (
    id bigint not null auto_increment,
    user_id bigint not null,
    email_notifications bit,
    push_notifications bit,
    sms_notifications bit,
    event_reminders bit,
    marketing_emails bit,
    created_at datetime(6),
    updated_at datetime(6),
    primary key (id)
) engine=InnoDB;

alter table users
    add constraint UK6dotkott2kjsp8vw4d0m25fb7 unique (email);

alter table users
    add constraint UKr43af9ap4edm43mmtq01oddj6 unique (username);

alter table notification_preferences
    add constraint UKn2jopkbm16qv3xelbvoyjkd0g unique (user_id);

alter table bookings
    add constraint FKeyog2oic85xg7hsu2je2lx3s6
    foreign key (user_id) references users (user_id);

alter table events
    add constraint FKat8p3s7yjcp57lny4udqvqncq
    foreign key (user_id) references users (user_id);
