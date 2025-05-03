/*
	Project: DvD Rental Data Analysis
	Database: dvdrental
*/

-- Data Exploration
-- ดึงข้อมูลลูกค้าในแต่ละเมือง

SELECT 
	city.city,
	COUNT(cus.customer_id) AS total_customer
FROM customer AS cus
INNER JOIN address AS add
	ON cus.address_id = add.address_id
INNER JOIN city
	ON add.city_id = city.city_id
GROUP BY city.city
ORDER BY total_customer DESC;

-- จำนวนหนังในแต่ละประเภท

SELECT 
	cat.name AS category,
	COUNT(film.film_id) AS total_film
FROM film
INNER JOIN film_category AS film_c
	ON film.film_id = film_c.film_id
INNER JOIN category AS cat
	ON film_c.category_id = cat.category_id
GROUP BY cat.name
ORDER BY total_film DESC;

SELECT 
	name AS category,
	(SELECT COUNT(*)
	 FROM film_category
	 WHERE category.category_id = film_category.category_id) AS total_film
FROM category
ORDER BY total_film DESC;

WITH total_film_per_category AS (
	SELECT category_id ,
		   COUNT(*) AS total_film
	FROM film_category
	GROUP BY category_id
)

SELECT 
	name,
	total_film
FROM category AS cat
LEFT JOIN total_film_per_category AS tfpc
ON cat.category_id = tfpc.category_id
ORDER BY total_film DESC;

-- Filtering & Conditions
-- หนังที่มีความยาว > 2 ชั่วโมง

SELECT 
	title,
	description,
	release_year,
	rating ,
	length
FROM film
WHERE length > 120;

-- ลูกค้าที่เคยเช่าหนังประเภท Action

SELECT first_name ||' '|| last_name AS name,
	film.title,
	cat.name AS category
FROM customer AS cus
INNER JOIN rental AS ren
	ON cus.customer_id = ren.customer_id
INNER JOIN inventory AS inv
	ON ren.inventory_id = inv.inventory_id
INNER JOIN film 
	ON inv.film_id = film.film_id
INNER JOIN film_category AS film_c
	ON film.film_id = film_c.film_id
INNER JOIN category AS cat
	ON film_c.category_id = cat.category_id
WHERE cat.name = 'Action';

-- ลูกค้าเช่าหนังทั้งหมดเท่าไหร่และลูกค้าคนไหนจ่ายเงินมากที่สุด

SELECT 
	first_name ||' '|| last_name AS name,
	COUNT(ren.rental_id) AS total_rental,
	SUM(pay.amount) AS sum_amount,
	RANK() OVER(ORDER BY SUM(pay.amount) DESC)
FROM customer AS cus
INNER JOIN payment AS pay
	ON cus.customer_id = pay.customer_id
INNER JOIN rental AS ren
	ON pay.rental_id = ren.rental_id
GROUP BY first_name ||' '|| last_name
ORDER BY sum_amount DESC;

-- รายได้แต่ละเดือน

SELECT EXTRACT(month FROM rental_date) AS month,
	EXTRACT(year FROM rental_date) AS year,
	SUM(amount) AS total_amount
FROM rental AS ren
INNER JOIN payment AS pay
	ON ren.rental_id = pay.rental_id
GROUP BY EXTRACT(year FROM rental_date),EXTRACT(month FROM rental_date)
ORDER BY year ASC, month ASC;

--- หนังประเภทไหนทำรายได้มากที่สุด

WITH film_per_category AS (
	SELECT film.film_id, cat.name AS category, film.rental_rate
	FROM film 
	INNER JOIN film_category AS film_c
		ON film.film_id = film_c.film_id
	INNER JOIN category AS cat
		ON film_c.category_id = cat.category_id
),
payment_rental AS (
	SELECT inv.film_id, pay.amount AS amount
	FROM payment AS pay
	INNER JOIN rental AS ren
		ON pay.rental_id = ren.rental_id
	INNER JOIN inventory AS inv
		ON ren.inventory_id = inv.inventory_id
)

SELECT film_p_cat.category,
	ROUND(SUM(pay_ren.amount),2) AS sum_amount
FROM film_per_category AS film_p_cat
INNER JOIN payment_rental AS pay_ren
	ON film_p_cat.film_id = pay_ren.film_id
GROUP BY film_p_cat.category
ORDER BY sum_amount DESC;

-- หาหนังที่ถูกเช่าบ่อยที่สุด 5 อันดับ

SELECT 
	film.title,
	COUNT(film.film_id) AS total_rental,
	ROW_NUMBER() OVER(ORDER BY COUNT(film.film_id) DESC) AS rank_rental
FROM rental AS ren
INNER JOIN inventory AS inv
	ON ren.inventory_id = inv.inventory_id
INNER JOIN film
	ON inv.film_id = film.film_id
GROUP BY film.title
ORDER BY total_rental DESC
LIMIT 5;

--- เฉลี่ยแต่ละประเภทหนังถูกเช่ากี่วัน

SELECT 
	cat.name AS category,
	ROUND(AVG(rental_duration),2) AS avg_rental_duration
FROM film
INNER JOIN film_category AS film_c
	ON film.film_id = film_c.film_id
INNER JOIN category AS cat
	ON film_c.category_id = cat.category_id
GROUP BY cat.name
ORDER BY avg_rental_duration DESC;

--- ลูกค้าที่จ่ายมากกว่าค่าเฉลี่ยของลูกค้าทั้งหมด

SELECT 
	first_name ||' '|| last_name AS name,
	pay.amount,
	ROW_NUMBER() OVER(ORDER BY pay.amount DESC) AS rank_customer
FROM customer AS cus
INNER JOIN payment AS pay
	ON cus.customer_id = pay.customer_id
WHERE pay.amount > (SELECT ROUND(AVG(amount),2) -- ค่าเฉลี่ยทั้งหมด = 4.20
					FROM payment) 