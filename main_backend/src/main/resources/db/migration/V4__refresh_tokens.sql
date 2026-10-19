-- Refresh tokens: only a SHA-256 hash of each token is stored. Every refresh
-- replaces the token with a new one in the same family; presenting a replaced
-- token again revokes the whole family (the token was copied).
create table refresh_tokens (
    id bigint not null auto_increment,
    token_hash varchar(64) not null,
    username varchar(255) not null,
    family_id varchar(36) not null,
    created_at datetime(6) not null,
    expires_at datetime(6) not null,
    revoked_at datetime(6),
    primary key (id),
    constraint uk_refresh_tokens_token_hash unique (token_hash)
) engine=InnoDB;

create index idx_refresh_tokens_family on refresh_tokens (family_id);
create index idx_refresh_tokens_expires_at on refresh_tokens (expires_at);
