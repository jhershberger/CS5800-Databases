--4)
CREATE INDEX w on teams (yearid, W DESC NULLS LAST);
SELECT 
    t.name, t.yearId, t.W
FROM
    teams T
INNER JOIN (SELECT 
            MAX(W) AS m, yearid
        FROM
            teams y
        GROUP BY yearid
                ) mx ON mx.yearid = t.yearid AND mx.m = t.W;
                
DROP INDEX w;

SELECT * FROM pg_indexes;


--5) 
CREATE INDEX mid ON batting(masterid);
SELECT
    C.yearID as year,
    name as teamName,
    C.lgID as league,
    D.cnt as totalBatters,
    C.cnt as aboveAverageBatters
FROM
    (SELECT 
        count(masterID) as cnt, A.yearID, A.teamID, A.lgID
    FROM
        (select 
        masterID,
            teamID,
            yearID,
            lgID,
            sum(AB),
            sum(H),
            sum(H)::float / sum(AB)::float as avg
    FROM
        batting
        WHERE AB > 0
    GROUP BY teamID , yearID , lgID , masterID) B, 
    (select a.teamID, 
            yearID,
            lgID,
            sum(AB),
            sum(H),
            sum(H)::float / sum(AB)::float as avg
    FROM
        batting a
    WHERE ab > 0
    GROUP BY teamID , yearID , lgID) A
    WHERE
        A.avg >= B.avg AND A.teamID = B.teamID
            AND A.yearID = B.yearID
            AND A.lgID = B.lgID
    GROUP BY A.teamID , A.yearID , A.lgID) C,
    (SELECT 
        count(masterID) as cnt, yearID, teamID, lgID
    FROM
        batting
    WHERE ab is not null
    GROUP BY yearID , teamID , lgID) D, 
    teams
WHERE
    C.cnt::float / D.cnt::float >= 0.75
        AND C.yearID = D.yearID
        AND C.teamID = D.teamID
        AND C.lgID = D.lgID
        AND teams.yearID = C.yearID
        AND teams.lgID = C.lgID
        AND teams.teamID = C.teamID;

WITH cnt AS (
        SELECT teamid, yearid, count(masterid) OVER (Partition BY teamid, yearid ORDER BY yearid) AS numBat
                , sum(h)::float / sum(ab)::float AS avg
        FROM batting
        WHERE ab > 0
        GROUP BY masterid, teamid, yearid, h, ab
), pavg AS (
        SELECt masterid, teamid, yearid
                , sum(h)::float / sum(ab)::float AS avg
        FROM batting
        WHERE ab > 0
        GROUP BY masterid, teamid, yearid, h, ab
)

SELECT DISTINCT tm.yearid, tm.teamid, tm.numBat, count(p.masterid) OVER (Partition BY p.masterid, p.yearid ORDER BY p.yearid) AS above_average_batters
FROM cnt AS tm
JOIN pavg AS p ON(p.teamid = tm.teamid AND p.yearid = tm.yearid AND (p.avg <= tm.avg))
GROUP BY tm.yearid, tm.teamid, tm.numBat, p.masterid, p.yearid
HAVING (count(p.masterid)::float / tm.numbat::float >= 0.75)
     
--CREATE INDEX belAvg ON batting (yearid, teamid, SUM(h)::float / sum(AB)::float AS avg DESC);

SELECT DISTINCT t.name, tAvg.yearid, t.lgid, tBatters.totB, p.count
FROM teamAvg AS tAvg 
INNER JOIN pAvg AS p ON (p.avg <= tAvg.avg AND p.teamid = tAvg.teamid AND p.yearid = t.yearid)
INNER JOIN (SELECT count(masterId) as totB, teamid, yearid FROM batting GROUP BY teamid, yearid) AS tBatters ON (tBatters.teamid = tAvg.teamid AND tBatters.yearid = tAvg.yearid)
JOIN teams AS t ON (tAvg.teamid = t.teamid)
GROUP BY t.name, tAvg.yearid, t.lgid, tBatters.totB
HaVING  p.count::float / tBatters.totB::float >= 0.75;


--cte
WITH pAvg AS (
        select B.masterID, B.teamID, B.yearID, B.lgid, sum(B.H)::float / sum(B.AB)::float as avg
            FROM batting AS B
            WHERE ab > 0
            GROUP BY teamID, yearID, lgid, masterid
), teamAvg AS (
     select tm.teamID, tm.yearID, tm.lgid, sum(tm.H)::float / sum(tm.AB)::float as avg
             FROM batting AS tm
             WHERE ab > 0
             GROUP BY teamID , yearID, lgid
)

SELECT
    C.yearID as year,
    t.name as teamName,
    t.lgID as league,
    count(D.masterid) as totalBatters,
    C.cnt as aboveAverageBatters
FROM batting AS D
JOIN (SELECT count(p.masterId) AS cnt, t.teamid, t.yearid, t.lgid
        FROM teamAvg AS T 
        JOIN pAvg AS p ON (p.avg <= t.avg AND T.teamid = p.teamid AND T.yearid = p.yearid)
        GROUP BY t.teamid, t.yearid, t.lgid
        ) C ON (C.teamid = D.teamid AND C.yearid = D.yearid )
JOIN teams t ON (t.teamid = C.teamid AND t.yearid = C.yearid)
GROUP BY C.yearid, t.name, t.lgid, C.cnt
HAVING C.cnt::float / count(d.masterid)::float >= 0.75 


--6
SELECT teamid FROM teams WHERE name='New York Yankees';
CREATE INDEX yankees ON teams(name);
CREATE INDEX players ON batting(teamid);
CREATE INDEX mid ON master(masterid);
ANALYZE teams;
EXPLAIN ANALYZE SELECT distinct
    master.nameFirst as "First Name", master.nameLast as "Last Name"
FROM
    (SELECT 
        b.masterID as ID, b.yearID as year
    FROM
        batting b, teams t
    WHERE
        name = 'New York Yankees'
            and b.teamID = t.teamID
            and b.yearID = t.yearID
            and t.lgID = b.lgID) y1,
    (SELECT 
        b.masterID as ID, b.yearID as year
    FROM
        batting b, teams t
    WHERE
        name = 'New York Yankees'
            and b.teamID = t.teamID
            and b.yearID = t.yearID
            and t.lgID = b.lgID) y2,
    (SELECT 
        b.masterID as ID, b.yearID as year
    FROM
        batting b, teams t
    WHERE
        name = 'New York Yankees'
            and b.teamID = t.teamID
            and b.yearID = t.yearID
            and t.lgID = b.lgID) y3,
    (SELECT 
        b.masterID as ID, b.yearID as year
    FROM
        batting b, teams t
    WHERE
        name = 'New York Yankees'
            and b.teamID = t.teamID
            and b.yearID = t.yearID
            and t.lgID = b.lgID) y4,
    master
WHERE
    y1.id = y2.id and y2.id = y3.id
        and y3.id = y4.id
        and y1.year + 1 = y2.year
        and y2.year + 1 = y3.year
        and y3.year + 1 = y4.year
        and y4.id = master.masterID
ORDER BY master.nameLast, master.nameFirst


SELECT * FROM pg_indexes;

DROP INDEX yankees;
DROP INDEX players;
DROP INDEX mid;

SELECT * FROM teams WHERE name='New York Yankees';

SELECT m.namefirst, m.namelast
FROM ( SELECT teamid, masterid, yearid, num_yrs = row_number() OVER (Partition BY teamid, masterid ORDER BY yearid)
        FROM batting WHERE teamid = 'NYA'; )


WITH cons_years AS (
        SELECT DISTINCT masterid, yearid, row_number() OVER (Partition BY teamid, masterid ORDER BY yearid) AS num_yrs
        FROM batting WHERE teamid = 'NYA'
)

SELECT m.namefirst, m.namelast
FROM cons_years AS c
JOIN master m ON (m.masterid = c.masterid) 
WHERE num_yrs = 4
ORDER BY m.namelast

--7)
SELECT 
    name,
    A.lgID,
    A.S as TotalSalary,
    A.yearID as Year,
    B.S as PreviousYearSalary,
    B.yearID as PreviousYear
FROM
    (SELECT 
        sum(salary) as S, yearID, teamID, lgID
    FROM
        salaries
    group by yearID , teamID , lgID) A,
    (SELECT 
        sum(salary) as S, yearID, teamID, lgID
    FROM
        salaries
    group by yearID , teamID , lgID) B,
    teams
WHERE
    A.yearID = B.yearID + 1
        AND (A.S * 2) <= (B.S)
        AND A.teamID = B.teamID
        AND A.lgID = B.lgID
        AND teams.yearID = A.yearID
        AND teams.lgID = A.lgID
        AND teams.teamID = A.teamID;

CREATE INDEX tid ON salaries(teamid);
CREATE INDEX yid ON salaries(yearid);
CREATE INDEX sid ON salaries(salary); 
CREATE INDEX ttid ON teams(teamid);     
WITH sal AS (
        SELECT DISTINCT teamid, yearid, sum(salary) OVER (PARTITION BY teamid, yearid) AS sumSal
        FROM salaries
    
)

SELECT DISTINCT t.name, yr.yearid, prev.yearid, yr.sumSal AS yearSal, prev.sumSal AS prevSal
FROM sal AS yr
JOIN teams AS t ON (t.teamid = yr.teamid AND t.yearid = yr.yearid)
JOIN sal AS prev ON (prev.yearid = yr.yearid -1 AND prev.teamid = yr.teamid AND (yr.sumSal * 2) <= (prev.sumSal) )

DROP INDEX tid;
DROP INDEX yid;
DROP INDEX sid;
DROP INDEX ttid;


        
