-- Q3 Channels

-- Q3 A: Funnel by application channel
SELECT channel_type,
	COUNT(*) AS applications,
	ROUND(100.0 * AVG((name_contract_status='Approved')::int),1) as approved_pct,
	ROUND(100.0 * AVG((name_contract_status='Refused')::int),1) as refused_pct,
	ROUND(100.0 * AVG((name_contract_status IN ('Canceled','Unused offer'))::int),1) as walked_away_pct
FROM previous_applications
GROUP BY channel_type
HAVING COUNT(*)>=1000
ORDER BY applications DESC;

/*
Result:

| channel_name                  | applications | approved_pct | refused_pct | walked_away_pct |
|-------------------------------|--------------|--------------|-------------|-----------------|
| Credit and cash offices       | 600342       | 40.7         | 20.9        | 38.4            |
| Country-wide                  | 423062       | 81.4         | 13.3        | 5.3             |
| Stone                         | 183508       | 89.2         | 10.4        | 0.5             |
| Regional / Local              | 92472        | 89.0         | 10.3        | 0.7             |
| Contact center                | 58891        | 36.7         | 21.8        | 41.5            |
| AP+ (Cash loan)               | 49624        | 54.5         | 39.0        | 6.5             |
| Channel of corporate sales    | 5396         | 43.0         | 54.8        | 2.2             |
*/

------------------------------------------------------------------------------------------------

-- Q3 B: Rank channels by refusal rate and walk-away rate

with ch as
(
SELECT channel_type,
	COUNT(*) as applications,
	AVG((name_contract_status='Refused')::int) as refused_rate,
	AVG((name_contract_status IN ('Canceled','Unused offer'))::int) as walked_rate
FROM previous_applications
GROUP BY channel_type
HAVING count(*)>1000
)
SELECT
	channel_type,
	applications,
	ROUND(100*refused_rate,1) as refused_pct,
	RANK() OVER(ORDER BY refused_rate DESC) AS refusal_rank,
	ROUND(100 * walked_rate,1) AS walked_away_pct,
	RANK() OVER(ORDER BY walked_rate DESC) AS walkaway_rank
FROM ch
ORDER by refusal_rank;

/*
Result:

| channel_name               | applications | refused_pct | refusal_rank | walked_away_pct | walked_away_rank |
|----------------------------|--------------|-------------|--------------|-----------------|------------------|
| Channel of corporate sales | 5396         | 54.8        | 1            | 2.2             | 5                |
| AP+ (Cash loan)            | 49624        | 39.0        | 2            | 6.5             | 3                |
| Contact center             | 58891        | 21.8        | 3            | 41.5            | 1                |
| Credit and cash offices    | 600342       | 20.9        | 4            | 38.4            | 2                |
| Country-wide               | 423062       | 13.3        | 5            | 5.3             | 4                |
| Stone                      | 183508       | 10.4        | 6            | 0.5             | 7                |
| Regional / Local           | 92472        | 10.3        | 7            | 0.7             | 6                |
*/

--







