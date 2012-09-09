# --- First database schema

# --- !Ups

create table item (
  id          bigint not null auto_increment,
  href        varchar(255),
  title       varchar(255),
  image       varchar(255),
  details     text,
  requested   int,
  purchased   int,
  price       double,
  primary key (id)
);

# --- !Downs

drop table if exists item;
