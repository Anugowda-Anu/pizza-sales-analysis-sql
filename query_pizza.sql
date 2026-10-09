use pizzahut;
-- 1. Retrieve the total number of orders placed.
select count(orderid) as total_orders from orders;

-- 2. Calculate the total revenue generated from pizza sales.
select round(sum(order_detail.quantity * pizzas.price),2) as total_sales
from order_detail join pizzas
on pizzas.pizza_id = order_detail.pizzaid;

-- 3. Identify the highest-priced pizza.
select pizza_types.name, pizzas.price as highest_price 
from pizza_types join pizzas 
on pizza_types.pizza_type_id=pizzas.pizza_type_id
order by pizzas.price desc limit 1;

-- 4. Identify the most common pizza size ordered.
select quantity, count(orderdid)
from order_detail group by quantity;

select pizzas.size ,count(order_detail.orderdid) as order_count
from pizzas join order_detail
on pizzas.pizza_id = order_detail.pizzaid
group by pizzas.size order by order_count desc ;

-- 5. List the top 5 most ordered pizza types along with their quantities.
-- name , sum-qty, - pizzas , pizzatype , order detail
select pizza_types.name , sum(order_detail.quantity) as tq
from pizza_types join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
join order_detail
on pizzas.pizza_id = order_detail.pizzaid
group by pizza_types.name order by tq desc limit 5;

-- 6. Join the necessary tables to find the total quantity of each pizza category ordered.
-- sum-qty, 
select pizza_types.category , sum(order_detail.quantity) as tq
from pizza_types join pizzas
on pizza_types.pizza_type_id = pizzas.pizza_type_id
join order_detail
on pizzas.pizza_id = order_detail.pizzaid
group by pizza_types.category order by tq desc;

-- 7. Determine the distribution of orders by hour of the day.
select hour(ordertime), count(orderid)
from orders group by hour(ordertime);

-- 8. Join relevant tables to find the category-wise distribution of pizzas.
select category, count(name) from pizza_types group by category;

-- 9. Group the orders by date and calculate the average number of pizzas ordered per day.
-- count-date, 
select orders.orderdate, sum(order_detail.quantity) 
from orders join order_detail
on orders.orderid = order_detail.orderdid
group by orders.orderdate ;

-- 10. Determine the top 3 most ordered pizza types based on revenue.-[ top 3 pizzatype name , based on price ]
-- price , name , orderid, pizzaid
Select pt.name, sum(od.quantity * p.price) as rev
from order_detail od
join pizzas p on od.pizzaid = p.pizza_id
join pizza_types pt on p.pizza_type_id = pt.pizza_type_id
group by pt.name
order by rev desc 
limit 3;

-- 11. Calculate the percentage contribution of each pizza type to total revenue.
SELECT
    pt.name AS pizza_types,
    SUM(od.quantity * p.price) AS total_revenue,
    ROUND(
        SUM(od.quantity * p.price) * 100.0 /
        (SELECT SUM(od2.quantity * p2.price)
         FROM order_detail od2
         JOIN pizzas p2
             ON od2.pizzaid = p2.pizza_id),
        2
    ) AS revenue_percentage
FROM order_detail od
JOIN pizzas p
    ON od.pizzaid = p.pizza_id
JOIN pizza_types pt
    ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY revenue_percentage DESC;

-- 12. Analyze the cumulative revenue generated over time.
SELECT
    order_date,
    daily_revenue,
    SUM(daily_revenue) OVER (
        ORDER BY order_date
    ) AS cumulative_revenue
FROM (
    SELECT
        o.orderdate AS order_date,
        SUM(od.quantity * p.price) AS daily_revenue
    FROM orders o
    JOIN order_detail od
        ON o.orderid = od.orderid
    JOIN pizzas p
        ON od.pizzaid = p.pizza_id
    GROUP BY o.orderdate
) AS daily_sales
ORDER BY order_date;

-- 13. Determine the top 3 most ordered pizza types based on revenue for each pizza category.
WITH pizza_revenue AS (
    SELECT
        pt.category,
        pt.name AS pizza_type,
        SUM(od.quantity * p.price) AS total_revenue
    FROM order_detail od
    JOIN pizzas p
        ON od.pizzaid = p.pizza_id
    JOIN pizza_types pt
        ON p.pizza_type_id = pt.pizza_type_id
    GROUP BY pt.category, pt.name
),
ranked_pizzas AS (
    SELECT
        category,
        pizza_type,
        total_revenue,
        DENSE_RANK() OVER (
            PARTITION BY category
            ORDER BY total_revenue DESC
        ) AS revenue_rank
    FROM pizza_revenue
)
SELECT
    category,
    pizza_type,
    total_revenue,
    revenue_rank
FROM ranked_pizzas
WHERE revenue_rank <= 3
ORDER BY category, revenue_rank;