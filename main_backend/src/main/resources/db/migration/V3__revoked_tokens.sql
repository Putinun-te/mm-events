-- Tokens ended by POST /api/auth/logout. A row is only needed until the token would
-- have expired anyway; expired rows are removed on the next logout.
create table revoked_tokens (
    token_id varchar(36) not null,
    expires_at datetime(6) not null,
    primary key (token_id)
) engine=InnoDB;

create index idx_revoked_tokens_expires_at on revoked_tokens (expires_at);
