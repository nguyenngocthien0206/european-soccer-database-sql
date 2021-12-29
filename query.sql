select * from sqlite_master where type='table'

--Check out all tables
select * from Country
select * from League
select * from Match
select * from Player
select * from Player_Attributes
select * from Team
select * from Team_Attributes

--Country vs League
select League.id,Country.name,League.name
from League
join Country
on League.id=Country.id

--Country vs League vs Team
select c.name as country_name, l.name as league_name, t.team_long_name
from League l
join Country c on l.country_id=c.id
join Match m on l.id=m.league_id
join Team t on t.team_api_id=m.home_team_api_id
group by t.team_api_id
order by c.name

--Player info
select pa.player_api_id as Player_api_id,p.player_name as Player_Name, strftime('%d-%m-%Y',p.birthday) as DOB, 
max(p.height) as Height, 
max(p.weight) as Weight,
round(avg(pa.overall_rating),2) as Rating,
round(avg(pa.potential),2) as Potenital,
pa.preferred_foot as Preferred_Foot,
pa.attacking_work_rate as Attacking_Work_Rate,
pa.defensive_work_rate as Defensive_Work_Rate
from Player p 
join Player_Attributes pa on p.player_api_id=pa.player_api_id and p.player_fifa_api_id=pa.player_fifa_api_id
group by pa.player_api_id

--Home team info
select match_api_id,home_team_api_id,team_long_name,team_short_name
from Match m
join Team t on t.team_api_id=m.home_team_api_id
group by match_api_id

--Away team info
select match_api_id,away_team_api_id,team_long_name,team_short_name
from Match m
join Team t on t.team_api_id=m.away_team_api_id
group by match_api_id

--Detailed matches
select m.id, c.name as country_name, l.name as league_name, m.season, m.stage,strftime('%d-%m-%Y',m.date) as "Date", ht.team_long_name as home_team,
at.team_long_name as away_team, m.home_team_goal,m.away_team_goal,
case
when m.home_team_goal>m.away_team_goal then ht.team_long_name
when m.home_team_goal<m.away_team_goal then at.team_long_name
else "Tie"
end as winner
from Match m
join Country c on c.id=m.country_id
join League l on l.id=m.league_id
join Team as ht on ht.team_api_id=m.home_team_api_id
join Team as at on at.team_api_id=m.away_team_api_id
order by m.date

--League stats by season (England,France,Germany,Spain,Italy)
select Match.id, Country.name as country_name, League.name as league_name, season,
count(distinct stage) as number_of_stages,
count(distinct HT.team_long_name) as number_of_teams,
round(avg(home_team_goal),2) as avg_home_team_scores,
round(avg(away_team_goal),2) as avg_away_team_goals,
round(avg(home_team_goal-away_team_goal),2) as avg_goal_diff,
round(avg(home_team_goal+away_team_goal),2) as avg_goals_scored,
sum(home_team_goal+away_team_goal) as total_goals_scored
from Match
join Country on Country.id=Match.country_id
join League on League.id=Match.league_id
join Team as HT on HT.team_api_id=Match.home_team_api_id
join Team as AT on AT.team_api_id=Match.away_team_api_id
where country_name in ('England','France', 'Germany', 'Spain', 'Italy')
group by country_name,league_name,season

--Goals scored by home team vs away team season on season
select m.season, l.name, sum(m.home_team_goal) as home_team_goals, sum(m.away_team_goal) as away_team_goals
from Match m
join League l on m.league_id=l.id
group by m.season,l.id
order by m.season

--Total games played by Team
select m.season, ht.team_long_name, count(m.home_team_api_id) as home_games_played, count(m.away_team_api_id) as away_games_played,
(count(m.home_team_api_id)+count(m.away_team_api_id)) as total_games_played
from Match m
join Team ht on m.home_team_api_id=ht.team_api_id
join Team at on m.away_team_api_id=at.team_api_id
group by m.season, ht.team_api_id
order by season,ht.team_long_name

--Matches won by Teams Season on Season
select tt.season,tt.winner, count(tt.winner) as wins
from(
	select m.id, c.name as country_name, l.name as league_name, m.season, m.stage,strftime('%d-%m-%Y',m.date) as "Date",
	ht.team_long_name as home_team,
	at.team_long_name as away_team, m.home_team_goal,m.away_team_goal,
	case
	when m.home_team_goal>m.away_team_goal then ht.team_long_name
	when m.home_team_goal<m.away_team_goal then at.team_long_name
	else "Tie"
	end as winner
	from Match m
	join Country c on c.id=m.country_id
	join League l on l.id=m.league_id
	join Team as ht on ht.team_api_id=m.home_team_api_id
	join Team as at on at.team_api_id=m.away_team_api_id
	where winner!="Tie"
	order by m.date) tt
group by tt.winner,tt.season
order by tt.season,tt.winner

--Win percentage
select tt1.team_long_name, tt1.total_games, tt2.total_wins, ROUND((100.0*tt2.total_wins/tt1.total_games),2) as win_percentage
from (
	select t1.team_long_name, sum(total_games_played) as total_games
	from (
		select m.season, ht.team_long_name, count(m.home_team_api_id) as home_games_played, count(m.away_team_api_id) as away_games_played,
		(count(m.home_team_api_id)+count(m.away_team_api_id)) as total_games_played
		from Match m
		join Team ht on m.home_team_api_id=ht.team_api_id
		join Team at on m.away_team_api_id=at.team_api_id
		group by m.season, ht.team_api_id) t1
	group by t1.team_long_name) tt1
join (
	select t3.winner, sum(t3.wins) as total_wins
	from (
		select t2.season,t2.winner, count(t2.winner) as wins
		from(
			select m.id, c.name as country_name, l.name as league_name, m.season, m.stage,strftime('%d-%m-%Y',m.date) as "Date",
			ht.team_long_name as home_team,
			at.team_long_name as away_team, m.home_team_goal,m.away_team_goal,
			case
			when m.home_team_goal>m.away_team_goal then ht.team_long_name
			when m.home_team_goal<m.away_team_goal then at.team_long_name
			else "Tie"
			end as winner
			from Match m
			join Country c on c.id=m.country_id
			join League l on l.id=m.league_id
			join Team as ht on ht.team_api_id=m.home_team_api_id
			join Team as at on at.team_api_id=m.away_team_api_id
			where winner!="Tie"
			order by m.date) t2
		group by t2.winner,t2.season) t3
	group by t3.winner)	tt2
on tt1.team_long_name=tt2.winner

