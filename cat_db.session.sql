-- create table cats (
--     id serial,
--     name text NOT NULL,
--     lives INT NOT NULL,
--     flaws text,
--     nicknames text[],
--     PRIMARY KEY (id)
-- );
-- drop table cats;
insert into cats (name, lives, flaws, nicknames)
VALUES ('kit', 9, null, '{"kitty", "kitten"}');