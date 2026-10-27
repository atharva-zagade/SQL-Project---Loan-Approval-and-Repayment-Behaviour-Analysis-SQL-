-- Q2 Refusal Reasons

-- Q2 A: Refusal reasons (refused applications only)

SELECT code_reject_reason,
	COUNT(*) AS refusals,
	ROUND(100.0* COUNT(*) / SUM(COUNT(*)) OVER(),2) as pct_of_refusals,
	ROUND(100.0 * SUM(COUNT(*)) OVER(ORDER BY COUNT(*) DESC)
			/SUM(COUNT(*)) OVER(),2) AS cumulative_pct
FROM previous_applications
WHERE name_contract_status = 'Refused'
GROUP BY code_reject_reason
ORDER BY refusals DESC;