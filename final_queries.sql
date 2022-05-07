use ipl;

-- Q1 : Toss Win Count for Each team and how many times did they choose bat and field?

select toss_winner, count(toss_decision) as toss_win,
count(case when toss_decision = 'bat' then 1 end) as bat,
count(case when toss_decision = 'field' then 1 end) as field
from ipl.matches
GROUP BY toss_winner ORDER BY toss_winner;

-- Q2 : Running total at each ball for all the matches

SELECT match_id, inning, concat(batting_team, " vs ", bowling_team), batting_team, `over`, ball, total_runs as run,
sum(total_runs) over (PARTITION BY match_id, inning rows UNBOUNDED PRECEDING) as TotalRuns
from ipl.deliveries
ORDER BY match_id, inning, `over`, ball;

-- Q3 : Batsman Stats

-- -- Strike Rate (Match Wise, Season Wise, Total)

-- Strike Rate Match Wise
Select batsman, match_id, sum(batsman_runs), count(ball),
sum(batsman_runs)/count(ball)*100 as Strike_Rate_Per_Match
from ipl.deliveries
GROUP BY batsman, match_id
ORDER BY batsman, match_id ASC;

-- Strike Rate Season Wise
select D.batsman, M.season, 
sum(D.batsman_runs)/count(D.ball)*100 as Strike_Rate_Per_Season
from ipl.deliveries D LEFT JOIN ipl.matches M
ON D.match_id = M.id
GROUP BY D.batsman, M.season
ORDER BY D.batsman, M.season;

-- Total Strike Rate
Select batsman, sum(batsman_runs), count(ball),
sum(batsman_runs)/count(ball)*100 as Strike_Rate_Per_Match
from ipl.deliveries
GROUP BY batsman
ORDER BY batsman;

-- Batting Average = Runs Scored / Number of Times Player got out
select batsman, Total_Runs, Dismissal_Count,  COALESCE(Total_Runs/Dismissal_Count, 'Unavailable') as Average 
from
(Select batsman, sum(batsman_runs) as Total_Runs
from ipl.deliveries
GROUP BY batsman) as Runs
left JOIN
(SELECT player_dismissed as Player, count(*) as Dismissal_Count
from ipl.deliveries
GROUP BY player_dismissed) as Outs
on Runs.batsman = Outs.Player;

-- Total Score in Each match
Select batsman, match_id,
sum(batsman_runs) as Total_Runs_Per_Match
from ipl.deliveries
GROUP BY batsman, match_id
ORDER BY batsman, match_id ASC;

-- Total run in each over of each match
Select batsman, match_id, `over` as over_no,
sum(batsman_runs) as Total_Runs_Overwise
from ipl.deliveries
GROUP BY batsman, match_id, `over`
ORDER BY batsman, match_id ASC, `over` ASC;

-- Total Runs
SELECT batsman, sum(batsman_runs) as Total_Runs
from ipl.deliveries
GROUP BY batsman
ORDER BY batsman;

-- Total 50s and 100s
Select batsman,
count(Case WHEN Total_Runs_Per_Match>99 then 1 end) as `100s_Count`,
count(Case WHEN Total_Runs_Per_Match<100 and Total_Runs_Per_Match>49 then 1 end) as `50s_Count`
from
(Select batsman, match_id,
sum(batsman_runs) as Total_Runs_Per_Match
from ipl.deliveries
GROUP BY batsman, match_id) Runs_Matchwise
GROUP BY batsman
ORDER BY batsman;


-- Q4 : Bowler Stats

-- Wicket Taken

select bowler,
count(case when dismissal_kind = 'bowled'
or dismissal_kind = 'caught'
or dismissal_kind = 'lbw'
or dismissal_kind = 'stumped'
or dismissal_kind = 'hit wicket'
or dismissal_kind = 'caught and bowled'
then 1 end) as Total_Wickets
from ipl.deliveries
GROUP BY bowler;

select bowler, dismissal_kind, fielder 
from ipl.deliveries
where dismissal_kind != '';

SELECT DISTINCT dismissal_kind 
FROM ipl.deliveries;

-- Economy Rate (Match Wise, Total)

select match_id, bowler, count(ball) as total_balls, sum(total_runs) as total_run, sum(total_runs)/count(ball)*6 as economy
from ipl.deliveries
GROUP BY match_id, bowler;

select bowler, count(ball) as total_balls, sum(total_runs) as total_run, sum(total_runs)/count(ball)*6 as economy
from ipl.deliveries
GROUP BY bowler;

-- Strike Rate
-- average number of balls bowled per wicket taken

SELECT Wicket.bowler, total_balls, Total_Wickets, total_balls/Total_Wickets as strike_rate 
from
(select bowler,
count(case when dismissal_kind = 'bowled'
or dismissal_kind = 'caught'
or dismissal_kind = 'lbw'
or dismissal_kind = 'stumped'
or dismissal_kind = 'hit wicket'
or dismissal_kind = 'caught and bowled'
then 1 end) as Total_Wickets
from ipl.deliveries
GROUP BY bowler) Wicket
inner join
(select bowler, count(ball) as total_balls
from ipl.deliveries
GROUP BY bowler) Ball
on Wicket.bowler = Ball.bowler;

-- Average
--  dividing the numbers of runs they have conceded by the number of wickets they have taken

SELECT Wicket.bowler, total_run, Total_Wickets, total_run/Total_Wickets as average 
from
(select bowler,
count(case when dismissal_kind = 'bowled'
or dismissal_kind = 'caught'
or dismissal_kind = 'lbw'
or dismissal_kind = 'stumped'
or dismissal_kind = 'hit wicket'
or dismissal_kind = 'caught and bowled'
then 1 end) as Total_Wickets
from ipl.deliveries
GROUP BY bowler) Wicket
inner join
(select bowler, sum(total_runs) as total_run
from ipl.deliveries
GROUP BY bowler) Run
on Wicket.bowler = Run.bowler;

-- Bowling Figure (Inning Wise)
-- A group of statistics listed for each bowler in a single innings:- 
-- number of overs bowled, number of maiden overs bowled, number of runs conceded and number of wickets taken.

SELECT BF1.match_id, BF1.bowler, Runs, overs, Total_Wickets, maiden_over
from
(select match_id, bowler, sum(total_runs) as Runs, count(ball)/6 as overs,
count(case when dismissal_kind = 'bowled'
or dismissal_kind = 'caught'
or dismissal_kind = 'lbw'
or dismissal_kind = 'stumped'
or dismissal_kind = 'hit wicket'
or dismissal_kind = 'caught and bowled'
then 1 end) as Total_Wickets
from ipl.deliveries
GROUP BY match_id, bowler) BF1
inner join
(SELECT match_id, bowler, count(case when max_Run_overWise=0 then 1 end) as maiden_over
from
(select match_id, bowler, `over`, max(total_runs) as max_Run_overWise
from ipl.deliveries
GROUP BY match_id, bowler, `over`) OverWise_Runs
GROUP BY match_id, bowler) BF2
on 
BF1.match_id = BF2.match_id and
BF1.bowler = BF2.bowler
ORDER BY BF1.match_id, BF1.bowler;


-- Fieler Stats

select replace(fielder, " (sub)", ""),
count(case when dismissal_kind = 'run out'
or dismissal_kind = 'stumped'
then 1 end) as Total_Wickets
from ipl.deliveries
GROUP BY replace(fielder, " (sub)", "")
ORDER BY 1;

-- Q5 : Team Stats
-- Q6 : Complete Tournament Stats

-- -- Extras

-- Wicket taken as Bowler and Fielder combined

SELECT bowler, sum(Total_Wickets)
from
(select bowler,
count(case when dismissal_kind = 'bowled'
or dismissal_kind = 'caught'
or dismissal_kind = 'lbw'
or dismissal_kind = 'stumped'
or dismissal_kind = 'hit wicket'
or dismissal_kind = 'caught and bowled'
then 1 end) as Total_Wickets
from ipl.deliveries
GROUP BY bowler

UNION ALL

select replace(fielder, " (sub)", ""),
count(case when dismissal_kind = 'run out'
or dismissal_kind = 'stumped'
then 1 end) as Total_Wickets
from ipl.deliveries
GROUP BY replace(fielder, " (sub)", "")

ORDER BY 1) TotalWickets
GROUP BY bowler;

Select * from ipl.deliveries;
SELECT * from ipl.matches;