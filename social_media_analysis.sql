




-- ==============================================================
-- SQL + GenAI Mini Project : Social Media Analytics
-- Dataset : Social_Media
-- Student Name : ______________________
-- ==============================================================

-- 🚀 SETUP INSTRUCTIONS (MUST DO FIRST)
-- ==============================================================
-- Before solving this project, make sure you create and load the dataset.
--
-- STEP 1: Open your SQL client (MySQL Workbench, DBeaver, or SQLite Studio).
-- STEP 2: Run the provided dataset file:
--         social_media_analytics_dataset.sql
--
-- This script will:
--   ✅ Create a new database named `Social_Media`
--   ✅ Create all 7 tables (users, posts, comments, likes, followers, hashtags, post_hashtags)
--   ✅ Insert ~7,000 synthetic rows for analysis
--
-- STEP 3: After successful execution, Your Code the database:
--         USE Social_Media;
--
-- STEP 4: Verify the tables:
--         SHOW TABLES;
--         Your Code COUNT(*) FROM users;
--         Your Code COUNT(*) FROM posts;
--
-- Once you confirm the data is loaded, you can proceed to attempt all project queries.
-- ==============================================================

USE Social_Media;

-- ==============================================================
-- IMPORTANT: BEFORE USING GenAI FOR QUERY GENERATION
-- ==============================================================
-- To help the AI generate accurate SQL, you MUST first share your schema.
-- Paste the following context into ChatGPT (or any GenAI tool) BEFORE you ask your prompts:

/*
You are an expert SQL assistant.  
Before answering any question, refer strictly to the database schema provided below.  
All SQL queries, joins, and analyses must be based ONLY on this schema — table names, column names, and relationships mentioned here.  
Do not assume any extra tables or columns unless explicitly stated.  
If a question is ambiguous, clarify it using the schema context rather than inventing new fields.  
Once you understand the schema, wait for my analytical question and generate the most accurate SQL query for it.

Tables and Key Columns:
  1. users(user_id, username, join_date, country)
  2. posts(post_id, user_id, content, created_at)
  3. comments(comment_id, post_id, user_id, comment_text, created_at)
  4. likes(like_id, post_id, user_id, created_at)
  5. followers(follower_id, user_id, follower_user_id, follow_date)
  6. hashtags(hashtag_id, tag_name, category)
  7. post_hashtags(id, post_id, hashtag_id)

Relationships:
  • Each user can create multiple posts.
  • Each post can have multiple likes and comments.
  • Users can follow each other (self-join in followers table).
  • Posts can be tagged with multiple hashtags (many-to-many via post_hashtags).
*/

-- Once you paste the schema, THEN use prompts like:
--   "Generate SQL to find top 10 active users combining posts and comments."
--   "Find trending hashtags used in more than 20 posts."
-- ==============================================================




-- ==============================================================
-- Q1. Most Active Users (Posts + Comments)
-- ==============================================================
-- Objective : Find top 10 users based on combined number of posts and comments.
-- Example GenAI Prompt :
--   "Write SQL to find top 10 active users combining posts and comments count."
-- Write your query below 👇
-- --------------------------------------------------------------
-- Your Code ...
select * from users;
select * from posts;
select * from comments;

SELECT 
    u.user_id,
    u.username,
    COUNT(DISTINCT p.post_id) AS posts,
    COUNT(DISTINCT c.comment_id) AS comments,
    COUNT(DISTINCT p.post_id) + COUNT(DISTINCT c.comment_id) AS total_activity
FROM
    users AS u
        LEFT JOIN
    posts AS p ON p.user_id = u.user_id
        LEFT JOIN
    comments AS c ON c.user_id = u.user_id
GROUP BY u.user_id , u.username
ORDER BY total_activity DESC
limit 10; 


-- Using subquery
SELECT 
    u.user_id,
    u.username,
    COALESCE(p.post_count, 0) AS posts,
    COALESCE(c.comment_count, 0) AS comments,
    COALESCE(p.post_count, 0) + COALESCE(c.comment_count, 0) AS total_activity
FROM
    users u
        LEFT JOIN
    (SELECT 
        user_id, COUNT(*) AS post_count
    FROM
        posts
    GROUP BY user_id) p ON u.user_id = p.user_id
        LEFT JOIN
    (SELECT 
        user_id, COUNT(*) AS comment_count
    FROM
        comments
    GROUP BY user_id) c ON u.user_id = c.user_id
ORDER BY total_activity DESC
limit 10;

-- using CTEs
with post_count as
 (SELECT 
        user_id, COUNT(*) AS post_count
    FROM
        posts
    GROUP BY user_id) ,
    comment_count as
    (SELECT 
        user_id, COUNT(*) AS comment_count
    FROM
        comments
    GROUP BY user_id)
    select u.user_id,u.username, coalesce(post_count,0) as posts, coalesce(comment_count,0) as comments, coalesce(post_count,0) + coalesce(comment_count,0) as total_activity
    from users as u
    left join post_count as p
    on u.user_id = p.user_id
    left join comment_count as c
    on c.user_id = u.user_id
    order by total_activity desc
    LIMIT 10; 
    
    

-- Solution Summary -- 


-- ==============================================================
-- Q2. Most Liked Posts and Creators
-- ==============================================================
-- Objective : Identify posts with maximum likes along with their creator.
-- Example GenAI Prompt :
--   "Show top 10 posts with most likes and username."
-- --------------------------------------------------------------
-- Your Code ...
select *  from posts;
select * from likes;
select * from users;
SELECT p.post_id,p.content,u.username as creator, COUNT(DISTINCT l.like_id) AS total_likes
FROM
posts AS p
inner JOIN likes AS l
ON p.post_id = l.post_id
inner JOIN users AS u
ON u.user_id= p.user_id
GROUP BY
    p.post_id,
    p.content,
    u.username
ORDER BY total_likes DESC
limit 10; 

-- using subquery
select p.post_id, p.content,u.username as creator, coalesce(l.total_likes,0) as total_likes
from posts as p
left join 
(select post_id, count(*) as total_likes
from likes
group by post_id)l
on p.post_id = l.post_id
left join users as u
on u.user_id = p.user_id
order by total_likes desc
limit 10;

-- using CTEs

with like_count as
(select post_id , count(*) as total_likes
from likes
group by post_id)
select p.post_id,u.username as creator,p.content,coalesce(l.total_likes,0) as total_likes
from posts as p
left join like_count as l
on p.post_id = l.post_id
left join users as u
on u.user_id = p.user_id
order by total_likes desc
limit 10;




-- Solution Summary -- 


-- ==============================================================
-- Q3. Top Countries by Average Engagement
-- ==============================================================
-- Objective : Find countries with the highest average likes per post.
-- Example GenAI Prompt :
--   "Which countries have highest average likes per post?"
-- --------------------------------------------------------------
-- Your Code ...
select * from users;
select * from posts;
select * from likes;

-- subqueery use for project average per post likes
SELECT
    country,
    avg(total_likes) AS avg_engagement
FROM
(
    SELECT
        u.country,
        p.post_id,
        COUNT(l.like_id) AS total_likes
    FROM users u
    JOIN posts p
        USING(user_id)
    LEFT JOIN likes l
        USING(post_id)
    GROUP BY
        u.country,
        p.post_id
) AS t
GROUP BY country
ORDER BY avg_engagement DESC
LIMIT 5;

select u.country,count(distinct p.post_id)as total_posts,count(l.like_id)as total_likes,round(coalesce(count(l.like_id)/nullif(COUNT(distinct p.post_id),0),0),2) as avg_engagement
from users as u
left join posts as p
on u.user_id = p.user_id
left join likes as l
on l.post_id = p.post_id
group by u.country
order by avg_engagement desc
limit 5;



-- using CTEs average engagement (likes + comments)
with likes_count as 
(select post_id, count(*) as total_like
from likes 
group by post_id),
comment_count as
(select post_id, count(*) as total_comment
from comments 
group by post_id)
select u.country, count(distinct p.post_id) as total_posts, sum(coalesce(l.total_like,0)) as total_likes, sum(coalesce(c.total_comment,0)) as total_comments, 
(
sum(coalesce(l.total_like,0))
 + 
 sum(coalesce(c.total_comment,0))
)
 / 
 nullif(count(distinct p.post_id),0) as avg_engagement
from users as u
left join posts as p
on u.user_id = p.user_id
left join likes_count as l
on l.post_id = p.post_id
left join comment_count as c
on c.post_id = p.post_id
group by u.country
order by avg_engagement desc;


-- using subquerry
SELECT
    u.country,
    count(distinct p.post_id) as total_posts,
    SUM(COALESCE(l.total_likes,0)) AS total_likes,
    SUM(COALESCE(c.total_comments,0)) AS total_comments,
    (SUM(COALESCE(l.total_likes,0)) + SUM(COALESCE(c.total_comments,0))) / NULLIF(count(distinct p.post_id) ,0) AS avg_engagement 
FROM posts p
JOIN users u
ON p.user_id = u.user_id
LEFT JOIN
(
    SELECT
        post_id,
        COUNT(*) AS total_likes
    FROM likes
    GROUP BY post_id
) l
ON p.post_id = l.post_id

LEFT JOIN
(
    SELECT
        post_id,
        COUNT(*) AS total_comments
    FROM comments
    GROUP BY post_id
) c
ON p.post_id = c.post_id

GROUP BY u.country
order by avg_engagement desc;







-- Solution Summary -- 


-- ==============================================================
-- Q4. Trending Hashtags (Used in >20 Posts)
-- ==============================================================
-- Objective : Find hashtags that appear in more than 20 posts.
-- Example GenAI Prompt :
--   "Find hashtags used in more than 20 posts."
-- --------------------------------------------------------------
-- Your Code ...
select * from post_hashtags;
select * from posts;
select * from hashtags;

select h.hashtag_id, h.tag_name, count(distinct ph.post_id) as total_posts
from hashtags as h
join post_hashtags as ph
on h.hashtag_id = ph.hashtag_id
group by h.hashtag_id,h.tag_name
having count(distinct ph.post_id) > 20
order by total_posts desc;



-- Solution Summary -- 


-- ==============================================================
-- Q5. Top Influencers (Users with Most Followers)
-- ==============================================================
-- Objective : List users with the highest follower count.
-- Example GenAI Prompt :
--   "Find users with maximum followers."
-- --------------------------------------------------------------
-- Your Code ...
select * from followers;
SELECT
    u2.user_id,
    u2.username AS influencer,
    COUNT(DISTINCT f.follower_user_id) AS total_followers
FROM followers AS f
JOIN users AS u1
ON f.follower_user_id = u1.user_id
JOIN users AS u2
ON f.user_id = u2.user_id
GROUP BY
    u2.user_id,
    u2.username
ORDER BY total_followers DESC
LIMIT 10;


-- Solution Summary -- 


-- ==============================================================
-- Q6. Followers Who Never Interacted
-- ==============================================================
-- Objective : Identify users who follow others but have never liked or commented.
-- Example GenAI Prompt :
--   "Show users who follow others but never interacted."
-- --------------------------------------------------------------
-- Your Code ...

select * from followers;

SELECT DISTINCT f.follower_user_id
FROM followers f
WHERE not exists (
    SELECT 1
    FROM likes l
    WHERE l.user_id = f.follower_user_id
)
and not exists (
    SELECT 1
    FROM comments c
    WHERE c.user_id = f.follower_user_id
);



-- learn not exists question by self
-- Find posts that have likes but no comments.
select p.post_id
from posts as p
where exists
 (select 1
 from likes AS l
 where p.post_id= l.post_id)
 and not exists 
 (select 1
 from comments as c
 where p.post_id= c.post_id);
 

 
 




-- Solution Summary -- 


-- ==============================================================
-- Q7. Hashtags with Highest Engagement
-- ==============================================================
-- Objective : Calculate total engagement (likes + comments) for each hashtag.
-- Example GenAI Prompt :
--   "Calculate engagement score per hashtag."
-- --------------------------------------------------------------
-- Your Code ...
select h.hashtag_id, h.tag_name,count(distinct l.like_id) as total_likes,count(distinct c.comment_id) as total_count, count(distinct l.like_id) + count(distinct c.comment_id) as total_engagement
from hashtags as h
inner join post_hashtags as ph
on h.hashtag_id = ph.hashtag_id
left join posts as p
on p.post_id = ph.post_id
left join likes as l 
on l.post_id = p.post_id
left join comments as c
on c.post_id = p.post_id
group by h.hashtag_id, h.tag_name
order by total_engagement desc;


-- using subquery, inner join left join aggregation
SELECT
    h.hashtag_id,
    h.tag_name,
    SUM(COALESCE(l.total_likes,0)) AS total_likes,
    SUM(COALESCE(c.total_comments,0)) AS total_comments,
    SUM(COALESCE(l.total_likes,0) + COALESCE(c.total_comments,0)) AS total_engagement
FROM hashtags h

JOIN post_hashtags ph
ON h.hashtag_id = ph.hashtag_id
LEFT JOIN
(
    SELECT
        post_id,
        COUNT(*) AS total_likes
    FROM likes
    GROUP BY post_id
) l
ON ph.post_id = l.post_id
LEFT JOIN
(
    SELECT
        post_id,
        COUNT(*) AS total_comments
    FROM comments
    GROUP BY post_id
) c
ON ph.post_id = c.post_id
GROUP BY
    h.hashtag_id,
    h.tag_name

ORDER BY total_engagement DESC;




 


-- Solution Summary -- 


-- ==============================================================
-- Q8. Busiest Posting Hours or Days
-- ==============================================================
-- Objective : Find which hour/day sees most posting activity.
-- Example GenAI Prompt :
--   "Write SQL to show which hour or weekday sees most posts."
-- --------------------------------------------------------------
-- Your Code ...
SELECT 
    DAYNAME(created_at) AS post_day,
    HOUR(created_at) AS post_hour,
    COUNT(*) AS total_posts
FROM
    posts
GROUP BY post_day , post_hour
ORDER BY total_posts DESC;







-- Solution Summary -- 


-- ==============================================================
-- Q9. Inactive Users
-- ==============================================================
-- Objective : Find users who have never posted, liked, or commented.
-- Example GenAI Prompt :
--   "Find users who have never posted, liked, or commented."
-- --------------------------------------------------------------
-- Your Code ...

-- using left join + null
select u.user_id
from users as u
left join posts as p
on p.user_id = u.user_id
left join likes as l
on l.user_id = u.user_id
left join comments as c
on c.user_id = u.user_id
where p.user_id IS NULL
AND l.user_id IS NULL
AND c.user_id IS NULL;


-- using not exists
select u.user_id, u.username
from users as u
where not exists
(select 1
from posts as p
where p.user_id = u.user_id)
and not exists
(select 1
from likes as l
where l.user_id = u.user_id)
and not exists
(select 1
from comments as c
where c.user_id = u.user_id); 





-- Solution Summary -- 


-- ==============================================================
-- Q10. Top Countries with Most Influencers
-- ==============================================================
-- Objective : Identify countries with the highest number of influencers.
-- Example GenAI Prompt :
--   "Generate SQL to find countries that have the most followed users."
-- --------------------------------------------------------------
-- Your Code ...
select u.country,count(distinct u.user_id) as influencers
from users as u
inner join followers as f
on u.user_id = f.user_id
group by u.country
order by influencers desc;




-- Solution Summary -- 


-- ==============================================================
-- BONUS CHALLENGES
-- ==============================================================
-- 1. Engagement rate = (likes + comments) / posts
-- 2. Mutual followers
-- 3. Most used hashtags by top 5 influencers
-- 4. Country-wise engagement leaderboard
-- --------------------------------------------------------------

-- ==============================================================
-- REFLECTION
-- ==============================================================
-- 1. How did GenAI assist you in solving these queries?
-- 2. What optimization tips did you learn?
-- 3. What business insights stood out to you?
-- ==============================================================
