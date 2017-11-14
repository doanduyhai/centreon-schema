CREATE KEYSPACE IF NOT EXISTS centreon WITH replication={'class': 'NetworkTopologyStrategy', 'realtime': 3};

CREATE TABLE IF NOT EXISTS centreon.databin (
	id_metric int,
	ctime bigint,
	value float,
	status tinyint,
	PRIMARY KEY((id_metric), ctime)
);

CREATE TABLE IF NOT EXISTS centreon.rrd_aggregated(
       service uuid,
       aggregation_unit text,
       time_value bigint, 
       id_metric int,
       previous_time_value bigint,
       min float,
       max float,
       sum float,
       count int,
PRIMARY KEY ((service,aggregation_unit,time_value),id_metric, previous_time_value));


CREATE TABLE IF NOT EXISTS centreon.analytics_aggregated(
       id_metric int,
       aggregation_unit text,
       time_value bigint, 
       previous_time_value bigint,
       min float,
       max float,
       sum float,
       count int,
PRIMARY KEY ((id_metric,aggregation_unit,time_value), previous_time_value));

CREATE TABLE IF NOT EXISTS centreon.metric_meta(
	id_metric int,
	service uuid,
	properties map<text, text>,
	PRIMARY KEY(id_metric)
);

CREATE TABLE IF NOT EXISTS centreon.service_meta(
	service uuid,
	id_metric int,
	PRIMARY KEY((service),id_metric)
);

CREATE OR REPLACE FUNCTION centreon.formatLongToDate(time_unit bigint)
RETURNS NULL ON NULL INPUT
RETURNS text
LANGUAGE java
AS $$
  final String rawDate = time_unit + "";
  final double yearDigitInSecondPrecision = time_unit / Math.pow(10, 13);
  final double yearDigitInHourPrecision = time_unit / Math.pow(10, 9);
  final double yearDigitInDayPrecision = time_unit / Math.pow(10, 7);
  final double yearDigitInMonthPrecision = time_unit / Math.pow(10, 5);
  if (yearDigitInSecondPrecision > 2 && yearDigitInSecondPrecision < 3) {
      // 2017 11 14 HH mm SS
      Double year = Math.floor(time_unit/(Math.pow(10,10)));
      Double month = Math.floor(time_unit/(Math.pow(10,8))) - (year * 100);
      Double day = Math.floor(time_unit/(Math.pow(10,6)))
              - (year * 10000 + month * 100);
      Double hour = Math.floor(time_unit/(Math.pow(10,4)))
              - (year * 1000000 + month * 10000 + day * 100);
      Double minute = Math.floor(time_unit/(Math.pow(10,2)))
              - (year * 100000000 + month * 1000000 + day * 10000 + hour * 100);
      Double second = time_unit
              - (year * 10000000000L + month * 100000000 + day * 1000000 + hour * 10000 + minute * 100);
      if (month > 12) {
          return rawDate;
      } else if (day > 31) {
          return rawDate;
      } else if (hour > 24) {
          return rawDate;
      } else if (minute > 59) {
          return rawDate;
      } else if (second > 59) {
          return rawDate;
      } else {
          return String.format("%d-%02d-%02d %02d:%02d:%02d GMT",
                  year.longValue(), month.longValue(), day.longValue(), hour.longValue(), minute.longValue(), second.longValue());
      }
  } else if (yearDigitInHourPrecision > 2 && yearDigitInHourPrecision < 3) {
      // 2017 11 14 HH
      Double year = Math.floor(time_unit/(Math.pow(10,6)));
      Double month = Math.floor(time_unit/(Math.pow(10,4))) - (year * 100);
      Double day = Math.floor(time_unit/(Math.pow(10,2)))
              - (year * 10000 + month * 100);
      Double hour = time_unit
              - (year * 1000000 + month * 10000 + day * 100);
      if (month > 12) {
          return rawDate;
      } else if (day > 31) {
          return rawDate;
      } else if (hour > 24) {
          return rawDate;
      } else {
          return String.format("%d-%02d-%02d %02d GMT", year.longValue(), month.longValue(), day.longValue(), hour.longValue());
      }
  } else if (yearDigitInDayPrecision > 2 && yearDigitInDayPrecision < 3) {
      // 2017 11 14
      Double year = Math.floor(time_unit/(Math.pow(10,4)));
      Double month = Math.floor(time_unit/(Math.pow(10,2))) - (year * 100);
      Double day = time_unit
              - (year * 10000 + month * 100);
      if (month > 12) {
          return rawDate;
      } else if (day > 31) {
          return rawDate;
      } else {
          return String.format("%d-%02d-%02d GMT", year.longValue(), month.longValue(), day.longValue());
      }
  } else if (yearDigitInMonthPrecision > 2 && yearDigitInMonthPrecision < 3) {
      // 2017 11
      Double year = Math.floor(time_unit/(Math.pow(10,2)));
      Double month = time_unit - (year * 100);
      if (month > 12) {
          return rawDate;
      } else {
          return String.format("%d-%02d GMT", year.longValue(), month.longValue());
      }
  } else {
      return rawDate;
  }
$$;

