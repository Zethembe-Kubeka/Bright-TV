SELECT *
FROM brighttv.subscription.bright_tv_dataset;

--CHECKING 2ND TABLE--
SELECT *
FROM brighttv.subscription.viewership;


--CHECKING WHICH USERID COLUMN MATCHES USERPROFILE BETTER--
SELECT
  COUNT(*) AS Total_Rows,
  SUM(CASE WHEN UserID0 = userid4 THEN 1 ELSE 0 END) AS Matching_Rows,
  SUM(CASE WHEN UserID0 <> userid4 THEN 1 ELSE 0 END) AS Mismatched_Rows
FROM brighttv.subscription.viewership;


--MATCH RATE OF UserID0 AGAINST USERPROFILE--
SELECT COUNT(DISTINCT B.UserID0) AS Matching_UserID0
FROM brighttv.subscription.viewership B
INNER JOIN brighttv.subscription.bright_tv_dataset A
  ON A.UserID = B.UserID0;


--MATCH RATE OF userid4 AGAINST USERPROFILE--
SELECT COUNT(DISTINCT B.userid4) AS Matching_userid4
FROM brighttv.subscription.viewership B
INNER JOIN brighttv.subscription.bright_tv_dataset A
  ON A.UserID = B.userid4;

  --DUPLICATES FOR USERPROFILE--
SELECT *,
  COUNT(*)
FROM brighttv.subscription.bright_tv_dataset
GROUP BY ALL
HAVING COUNT(*) >1;
--NO DUPLICATES UNDER USERPROFILE--


--DUPLICATES FOR VIEWERSHIP--
SELECT *,
  COUNT(*)
FROM brighttv.subscription.viewership
GROUP BY ALL
HAVING COUNT(*) >1;
--5 DUPLICATED ROWS UNDER VIEWERSHIP--


--REMOVING VIEWERSHIP DUPLICATES--
CREATE OR REPLACE TEMP VIEW viewership AS
SELECT *
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY UserID0, RecordDate2, Channel2, `Duration 2` 
        ORDER BY RecordDate2) AS row_num
    FROM brighttv.subscription.viewership)
WHERE row_num = 1;


--USING JOINS TO VIEW TABLES--
SELECT
  A.UserID,
  A.Gender,
  A.Race,
  A.Age,
  A.Province,
  B.Channel2,
  B.RecordDate2,
  B.`Duration 2`,
  B.userid4
FROM brighttv.subscription.bright_tv_dataset A
INNER JOIN brighttv.subscription.viewership B
  ON A.UserID = B.UserID0;


--Unique rows--
SELECT 
    COUNT(DISTINCT UserID) AS Distinct_user
FROM (
    SELECT 
        A.UserID,
        A.Gender,
        A.Race,
        A.Age,
        A.Province,
        B.Channel2,
        B.`RecordDate2`,
        B.`Duration 2`
    FROM brighttv.subscription.bright_tv_dataset AS A
    INNER JOIN brighttv.subscription.viewership AS B
    ON A.UserID = B.UserID0 ) AS joined_tables;


    ---NULL FUNCTIONS IN USERPROFILE--
SELECT 
  IFNULL(UserID, '0') AS UserID,
  IFNULL(Gender, 'None') AS Gender,
  IFNULL(Race, 'None') AS Race,
  IFNULL(ROUND(Age, '0'), 0) AS Age,
  IFNULL(Province, 'None') AS Province
FROM brighttv.subscription.bright_tv_dataset;


--NULL FUNCTIONS IN VIEWERSHIP--
SELECT
  IFNULL(Channel2, 'None') AS Channel2,
  IFNULL(RecordDate2, 'None') AS RecordDate2,
  IFNULL(`Duration 2`, 'None') AS Duration2
FROM brighttv.subscription.viewership;


--CONVERT RECORDDATE TO SA TIME--
SELECT
    UserID0,
    Channel2,
    FROM_UTC_TIMESTAMP(TO_TIMESTAMP(RecordDate2),'Africa/Johannesburg') AS RecordDate_SAST,
    TO_DATE(FROM_UTC_TIMESTAMP(TO_TIMESTAMP(RecordDate2),'Africa/Johannesburg' )) AS Date_part,
    DATE_FORMAT(FROM_UTC_TIMESTAMP(TO_TIMESTAMP(RecordDate2),'Africa/Johannesburg' ),'HH:mm:ss') AS Time_part
FROM brighttv.subscription.viewership;

--Convert Duration 2 (HH:MM:SS) into hours, rounded to 2 decimal places--
SELECT
  `Duration 2`,
  ROUND((HOUR(`Duration 2`) * 3600 + MINUTE(`Duration 2`) * 60 + SECOND(`Duration 2`)) / 3600.0,2) AS Duration_Hours
FROM brighttv.subscription.viewership;


--CATERORY--
SELECT
  *,
  CASE
    WHEN Duration_Hours < 0.25 THEN 'Short (<15 min)'
    WHEN Duration_Hours < 1 THEN 'Medium (15-60 min)'
    WHEN Duration_Hours < 3 THEN 'Long (1-3 hrs)'
    ELSE 'Extended (3+ hrs)'
  END AS Duration_Category
FROM (
  SELECT
    `Duration 2`,
    ROUND((HOUR(`Duration 2`) * 3600 + MINUTE(`Duration 2`) * 60 + SECOND(`Duration 2`)) / 3600.0, 2) AS Duration_Hours
  FROM brighttv.subscription.viewership);


-- Confirm row count and date range after cleaning
SELECT
  COUNT(*) AS Row_Count,
  MIN(RecordDate2) AS Earliest_Date,
  MAX(RecordDate2) AS Latest_Date
FROM brighttv.subscription.viewership;


--Consumption is split--
SELECT
  UserID0,
  COUNT(*) AS Session_Count,
  ROUND(SUM((HOUR(`Duration 2`) * 3600 + MINUTE(`Duration 2`) * 60 + SECOND(`Duration 2`)) / 3600.0), 2) AS Total_Hours_Watched,
  ROUND(AVG((HOUR(`Duration 2`) * 3600 + MINUTE(`Duration 2`) * 60 + SECOND(`Duration 2`)) / 3600.0), 2) AS Avg_Hours_Per_Session
FROM brighttv.subscription.viewership
GROUP BY ALL
ORDER BY ALL DESC;


-- Total and average hours watched per Province
SELECT
  A.Province,
  COUNT(*) AS Session_Count,
  ROUND(SUM((HOUR(B.`Duration 2`) * 3600 + MINUTE(B.`Duration 2`) * 60 + SECOND(B.`Duration 2`)) / 3600.0), 2) AS Total_Hours_Watched,
  ROUND(AVG((HOUR(B.`Duration 2`) * 3600 + MINUTE(B.`Duration 2`) * 60 + SECOND(B.`Duration 2`)) / 3600.0), 2) AS Avg_Hours_Per_Session
FROM brighttv.subscription.bright_tv_dataset A
INNER JOIN brighttv.subscription.viewership B
  ON A.UserID = B.UserID0
GROUP BY A.Province
ORDER BY Total_Hours_Watched DESC;


--VIEWERSHIP BASED ON AGE--
SELECT 
      `Age`,
  CASE
    WHEN Age < 18 THEN 'Under age'
    WHEN Age BETWEEN 18 AND 24 THEN 'Young adult'
    WHEN Age BETWEEN 25 AND 34 THEN 'Adult'
    WHEN Age BETWEEN 35 AND 44 THEN 'Old'
    WHEN Age BETWEEN 45 AND 54 THEN 'Very Old'
    WHEN Age BETWEEN 55 AND 64 THEN 'Senior'
    ELSE 'Pensioner'
  END AS Age_group
FROM brighttv.subscription.bright_tv_dataset;


--CLEANED DATE
CREATE OR REPLACE TEMP VIEW cleaned_data AS
SELECT
  IFNULL(A.UserID, 0) AS UserID,
  IFNULL(A.Gender, 'None') AS Gender,
  IFNULL(A.Race, 'None') AS Race,
  IFNULL(ROUND(A.Age, 0), 0) AS Age,
  CASE
    WHEN A.Age < 18 THEN 'Under age'
    WHEN A.Age BETWEEN 18 AND 24 THEN 'Young adult'
    WHEN A.Age BETWEEN 25 AND 34 THEN 'Adult'
    WHEN A.Age BETWEEN 35 AND 44 THEN 'Old'
    WHEN A.Age BETWEEN 45 AND 54 THEN 'Very Old'
    WHEN A.Age BETWEEN 55 AND 64 THEN 'Senior'
    ELSE 'Pensioner'
  END AS Age_Group,
  IFNULL(A.Province, 'None') AS Province,
  IFNULL(B.Channel2, 'None') AS Channel2,
  FROM_UTC_TIMESTAMP(TO_TIMESTAMP(B.RecordDate2), 'Africa/Johannesburg') AS RecordDate_SAST,
  CAST(FROM_UTC_TIMESTAMP(TO_TIMESTAMP(B.RecordDate2), 'Africa/Johannesburg') AS DATE) AS Date_Part,
  DATE_FORMAT(FROM_UTC_TIMESTAMP(TO_TIMESTAMP(B.RecordDate2), 'Africa/Johannesburg'), 'HH:mm:ss') AS Time_Part,
  ROUND((HOUR(B.`Duration 2`) * 3600 + MINUTE(B.`Duration 2`) * 60 + SECOND(B.`Duration 2`)) / 3600.0, 2) AS Duration_Hours,
  CASE
    WHEN ROUND((HOUR(B.`Duration 2`) * 3600 + MINUTE(B.`Duration 2`) * 60 + SECOND(B.`Duration 2`)) / 3600.0, 2) < 0.25 THEN 'Short (<15 min)'
    WHEN ROUND((HOUR(B.`Duration 2`) * 3600 + MINUTE(B.`Duration 2`) * 60 + SECOND(B.`Duration 2`)) / 3600.0, 2) < 1 THEN 'Medium (15-60 min)'
    WHEN ROUND((HOUR(B.`Duration 2`) * 3600 + MINUTE(B.`Duration 2`) * 60 + SECOND(B.`Duration 2`)) / 3600.0, 2) < 3 THEN 'Long (1-3 hrs)'
    ELSE 'Extended (3+ hrs)'
  END AS Duration_Category
FROM brighttv.subscription.bright_tv_dataset A
INNER JOIN brighttv.subscription.viewership B
  ON A.UserID = B.UserID0;

--VALIDATION: ROW COUNT AND DATE RANGE ON THE FULLY CLEANED DATASET--
SELECT
  COUNT(*) AS Row_Count,
  MIN(RecordDate_SAST) AS Earliest_Date,
  MAX(RecordDate_SAST) AS Latest_Date
FROM cleaned_data;


--CONSUMPTION PER SUBSCRIBER (1 RECORD PER SESSION)--
SELECT
  UserID,
  COUNT(*) AS Session_Count,
  ROUND(SUM(Duration_Hours), 2) AS Total_Hours_Watched,
  ROUND(AVG(Duration_Hours), 2) AS Avg_Hours_Per_Session
FROM cleaned_data
GROUP BY UserID
ORDER BY Total_Hours_Watched DESC;


--VIEWWERSHIP BY AGE--
SELECT
  A.Age,
  COUNT(*) AS Session_Count,
  ROUND(SUM((HOUR(B.`Duration 2`) * 3600 + MINUTE(B.`Duration 2`) * 60 + SECOND(B.`Duration 2`)) / 3600.0), 2) AS Total_Hours_Watched,
  ROUND(AVG((HOUR(B.`Duration 2`) * 3600 + MINUTE(B.`Duration 2`) * 60 + SECOND(B.`Duration 2`)) / 3600.0), 2) AS Avg_Hours_Per_Session
FROM brighttv.subscription.bright_tv_dataset A
INNER JOIN brighttv.subscription.viewership B
  ON A.UserID = B.UserID0
GROUP BY A.Age
ORDER BY Total_Hours_Watched DESC;


--VIEWERSHIP BY GENDER--
SELECT
  A.Gender,
  COUNT(*) AS Session_Count,
  ROUND(SUM((HOUR(B.`Duration 2`) * 3600 + MINUTE(B.`Duration 2`) * 60 + SECOND(B.`Duration 2`)) / 3600.0), 2) AS Total_Hours_Watched,
  ROUND(AVG((HOUR(B.`Duration 2`) * 3600 + MINUTE(B.`Duration 2`) * 60 + SECOND(B.`Duration 2`)) / 3600.0), 2) AS Avg_Hours_Per_Session
FROM brighttv.subscription.bright_tv_dataset A
INNER JOIN brighttv.subscription.viewership B
  ON A.UserID = B.UserID0
GROUP BY A.Gender
ORDER BY Total_Hours_Watched DESC;


--VIEWERSHIP BY DURATION CATEGORY (SESSION LENGTH DISTRIBUTION)--
SELECT
  Duration_Category,
  COUNT(*) AS Session_Count,
  ROUND(SUM(Duration_Hours), 2) AS Total_Hours_Watched
FROM cleaned_data
GROUP BY Duration_Category
ORDER BY Session_Count DESC;
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
--CREATING ONE BIG TABLE---

SELECT
  UserID,
  Gender,
  Race,
  Age,
  Age_Group,
  Province,
  Channel2,
  RecordDate_SAST,
  Date_Part,
  Time_Part,
  Duration_Hours,
  Duration_Category,
  COUNT(*) AS Session_Count,
  ROUND(SUM(Duration_Hours), 2) AS Total_Hours_Watched,
  ROUND(AVG(Duration_Hours), 2) AS Avg_Hours_Per_Session
FROM cleaned_data
GROUP BY ALL; 