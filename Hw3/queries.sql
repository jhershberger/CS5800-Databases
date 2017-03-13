#1) I assume that every player has batted before and is represented in the batting table
SELECT DISTINCT m.nameFirst AS 'First Name', m.nameLast AS 'Last Name'
FROM batting as b
JOIN master AS m ON (b.masterID = m.masterID)
JOIN teams AS t ON (t.teamID = b.teamID) 
WHERE (t.name = "Los Angeles Dodgers");

#2) Do a not in statement in the where clause to make sure the masterId of the player 
#isn't in the table that returns every masterId of players who have played for any team other than
# the dodgers. Then make sure the masterId did play for the dodgers and return the results.
SELECT DISTINCT m.nameFirst AS 'First Name', m.nameLast AS 'Last Name'
FROM master AS m 
WHERE m.masterID NOT IN (SELECT masterID 
						 FROM teams AS t 
                         JOIN batting AS b ON (b.teamID = t.teamID AND b.yearID = t.yearID) 
                         WHERE t.name != "Los Angeles Dodgers" AND t.name != "Brooklyn Dodgers") 
AND masterID IN ( SELECT masterID 
				  FROM teams as t1
				  JOIN batting AS b1 ON (b1.teamID = t1.teamID AND t1.yearID = b1.yearID)
				  WHERE t1.name = "Los Angeles Dodgers" OR t1.name = "Brooklyn Dodgers")
ORDER BY m.nameLast;

#3) check that the year the player won the gold glove is the same year they were
#on the team
SELECT DISTINCT m.nameFirst AS 'First Name', m.nameLast AS 'Last Name'
				, a.yearID AS 'Year', a.notes AS 'Position'
FROM fielding AS f
JOIN master AS m ON (f.masterID = m.masterID)
JOIN awardsplayers AS a ON (a.masterID = m.masterID)
JOIN teams AS t ON (t.teamID = f.teamID AND f.yearID = t.yearID)
WHERE (t.name = "Los Angeles Dodgers" AND a.awardID = "Gold Glove" AND (a.yearID = t.yearID));

#4) count the number of rows for each team that has the column where WSWin = 'y'
#Group by each team name
SELECT t.name, COUNT(*) AS 'WS Titles' FROM teams AS t
WHERE (t.WSWin = 'y')
GROUP BY t.name;

#5) Only get the players who have actually had an AB, get their numbers from batting
SELECT DISTINCT m.nameFirst, m.nameLast, b.yearID, b.H, b.AB, (b.H/b.AB)
FROM batting AS b
JOIN master AS m ON (m.masterID = b.masterID)
JOIN schoolsplayers AS s ON (m.masterID = s.masterID AND s.schoolID = "utahst")
WHERE (b.AB IS NOT NULL);

#6) Do a sub query to get the year's salary that was 150% percent more than the previous
# year.
SELECT t.name, s.lgID, s.yearID, sum(s.salary) AS PrevSalary, yr.yearID, yrSum AS 'Salary', round((yrSum / sum(s.salary)) * 100, 1) AS 'Percent Increase'
FROM salaries AS s
JOIN ( SELECT teamID, yearID, sum(salary) AS yrSum
		FROM salaries
        GROUP BY teamID, yearID ) AS yr on (yr.teamID = s.teamID AND yr.yearID = s.yearID+1)
JOIN teams AS t ON (s.teamID = t.teamID AND s.yearID = t.yearID)
GROUP BY s.yearID, s.teamID
HAVING ((yrSum / sum(s.salary)) > 1.5);

#7) do a sub query so that we get years that are greater than the initial year, 
#check for a range of years such that the count of consecutive years that a hitter 
#had an AB for Boston Red Sox is >= 4. 
SELECT DISTINCT p.nameFirst, p.nameLast, t.name
FROM batting AS b
JOIN ( SELECT masterID,yearID,teamID 
		FROM batting 
        ) AS a ON (a.masterID = b.masterID AND b.teamID = a.teamID AND a.yearID > b.yearID)
JOIN master as p ON (p.masterID = b.masterID)
JOIN teams AS t ON (t.teamID = b.teamID)
WHERE (t.name = "Boston Red Sox" AND a.yearID - b.yearID = (SELECT (COUNT(yearID) - 1) AS cnt FROM batting AS c WHERE (c.masterID = b.masterID AND c.yearID BETWEEN b.yearID AND a.yearID) HAVING (cnt >= 3)));

#8) Get the max hr for each year and return each player who hit that for that year
SELECT p.nameFirst, p.nameLast, b.HR, b.yearID
FROM batting AS b 
JOIN master AS p ON (b.masterID = p.masterID)
JOIN ( SELECT max(HR) AS hr, yearID FROM batting GROUP BY yearID) c ON (c.yearID = b.yearID AND c.hr = b.HR)
GROUP BY b.yearID, p.nameLast;

#9) To get the third highest HR total, sort each year by home runs and select the third row
#from each year. 
SELECT m.nameFirst, m.nameLast, b.yearID, b.HR
FROM batting AS b, master AS m,
	(SELECT masterID, yearID, HR
		FROM (SELECT a.masterID, a.yearID, a.HR, count(*) as cnt
				FROM (SELECT masterID, yearID, HR, count(*) as cnt
						FROM batting
						GROUP BY yearID, HR) AS a,
			  (SELECT masterID, yearID, HR, count(*) as cnt
				FROM batting
				GROUP BY yearID, HR) AS b
		WHERE a.HR < b.HR AND a.yearID = b.yearID
		GROUP by a.yearID, a.HR) AS d
	WHERE d.cnt = 2) AS thrd    
WHERE (b.HR = thrd.HR AND b.yearID = thrd.yearID AND b.masterID = m.masterID)
ORDER BY b.yearID;

#10) To get both the 3B hit by both players,  a sub query needs to be made such that the players
# are on the same team and hit
SELECT DISTINCT t.name, b.yearID, m.nameFirst, m.nameLast, b.3B, tm.nameFirst, tm.nameLast, tmate.3B
FROM batting AS b
JOIN master AS m ON (b.masterID = m.masterID)
JOIN (SELECT DISTINCT masterID, teamID, yearID, 3B FROM batting WHERE (3B >= 10)) AS tmate ON (tmate.teamID = b.teamID AND tmate.yearID = b.yearID AND tmate.masterID != b.masterID)
JOIN master AS tm ON (tm.masterID = tmate.masterID)
JOIN teams AS t ON (b.teamID = t.teamID)
WHERE (b.3B >= 10 AND b.3B <= tmate.3B)
GROUP BY tm.nameLast
ORDER BY yearID;

#11) Set a variable rank which will simply number the row, order by win percentage
SELECT t.name, @rank := @rank + 1 AS Rank, winPerc, sum(t.W) AS 'Total Wins', sum(t.L) AS 'Total Losses'
FROM ( SELECT name, @rank:=0,  sum(W) / sum(W + L) AS winPerc, sum(W) AS W, sum(L) AS L FROM teams GROUP BY name ORDER BY winPerc DESC ) AS t
GROUP BY t.name
ORDER BY winPerc DESC;

#12) Get the master id's for casey stengel and all of his pitchers by checking the teamId and yearID and return their names
SELECT DISTINCT t.name, pi.yearID, p.nameFirst AS pitchFirst, p.nameLast AS pitchLast, csteng.nameFirst AS manFirst, csteng.nameLast As manLast
FROM managers AS man 
JOIN pitching AS pi ON (man.teamID = pi.teamID and man.yearID = pi.yearID)
JOIN master AS p ON (pi.masterID = p.masterID)
JOIN master AS csteng ON (csteng.nameFirst = "Casey" AND csteng.nameLast = "Stengel")
JOIN teams AS t ON (man.teamID = t.teamID AND man.yearID = t.yearID)
WHERE (man.masterID = csteng.masterID)
GROUP BY pitchLast
ORDER BY yearID;

#13) get the teamates of yogi berra and make sure the 2d master id isn't in there, join the batting table
#where one of 1d id's is a teamate with the 2d id and yogi was on a different team. 
SELECT DISTINCT m.nameFirst, m.nameLast
FROM batting AS 2d
JOIN master AS m ON (m.masterID = 2d.masterID)
JOIN batting AS yb ON (yb.masterID = "berrayo01")
JOIN batting AS 1d ON (2d.yearID = 1d.yearID AND 2d.teamID = 1d.teamID AND yb.teamID != 2d.teamID AND yb.yearID = 2d.yearID)
WHERE 2d.masterID NOT IN (
	SELECT tm.masterID 
	FROM batting AS tm
	JOIN (SELECT teamID, yearID 
		  FROM batting
		  WHERE (masterID = "berrayo01")
		  GROUP BY yearID) AS yb ON (tm.teamID = yb.teamID AND tm.yearID = yb.yearID)
	WHERE (tm.masterID != "berrayo01"))
AND 1d.masterID IN (
	SELECT tm.masterID 
	FROM batting AS tm
	JOIN (SELECT teamID, yearID 
		  FROM batting
		  WHERE (masterID = "berrayo01")
		  GROUP BY yearID) AS yb ON (tm.teamID = yb.teamID AND tm.yearID = yb.yearID)
	WHERE (tm.masterID != "berrayo01"));
	
#14) The sub query gets all the teamID's that aren't in the table that returns all the teamID's that rickey played for
#we check against rickey's debut and his final game to make sure the proper teams are listed
SELECT t.name
FROM( SELECT teamID, yearID FROM batting AS b WHERE teamID NOT in (SELECT teamID FROM batting AS tm WHERE (tm.masterID = "henderi01"))) AS dnp
JOIN teams AS t ON (dnp.teamID = t.teamID AND dnp.yearID = t.yearID)
JOIN master AS rh ON (rh.nameFirst = "Rickey" AND rh.nameLast = "Henderson")
WHERE (dnp.yearID >= EXTRACT(YEAR FROM rh.debut) AND dnp.yearID <= EXTRACT(YEAR FROM rh.finalGame))
GROUP BY t.name;
