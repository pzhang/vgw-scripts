CREATE TABLE call_data (id serial, time timestamp, channel integer, event varchar(255), code integer, number bigint, source varchar(255), PRIMARY KEY(id));
CREATE INDEX call_data_time_index ON call_data(time);
