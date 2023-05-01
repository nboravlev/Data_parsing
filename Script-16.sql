-- Оконные функции

create schema _mosinfo 

--1)
--Есть отчётная таблица work_hours за прошедший месяц, 
--в которой содержатся данные по районам о количестве часов, 
--которое дворники провели за работой

create table zuz_sevbut (
dvornik varchar(10) not null,
district varchar (50) not null,
hours numeric check (hours >= 0)
)

insert into zuz_sevbut (dvornik,district,hours)
select unnest(array['zuzi_1','zuzi2','zuzi_3','zuzi_4','zuzi_5','sevbut_1','sevbut_2','sevbut_3','sevbut_4','sevbut_5']),
	unnest(array['Зюзино','Зюзино','Зюзино','Зюзино','Зюзино','Сев.Бутово','Сев.Бутово','Сев.Бутово','Сев.Бутово','Сев.Бутово']),
	unnest(array[180,192,200,208,240,140,156,172,192,208])
	
--Мы хотим для каждого дворника увидеть, 
--сколько процентов составляет его значение отработанных часов
-- от максимального значения в районе
--Проценты нужно округлить до целого значения.


select *, round(hours/max(hours) over (partition by district) * 100,0) as Procent
from zuz_sevbut

--Мы хотим для каждого дворника увидеть, 
--сколько процентов составляет количество отработанным им часов от общего 
--количества часов, которые провели дворники текущего района за работой 
--в прошедшем месяце.

select *, sum(hours) over (partition by district) as dist_hours, 
	round(hours/sum(hours) over (partition by district)*100,0) as perc
from zuz_sevbut


--3) Есть таблица дворников по району Зюзино zuzi_dvorniks 
--c количеством отработанных ими часов за прошлый месяц.

create table zuzi_dvorniks (
dvornik varchar(10) not null,
uchastok varchar(10) not null,
hours numeric check (hours >= 0)
)

insert into zuzi_dvorniks (dvornik,uchastok,hours)
select unnest(array['zuzi_1','zuzi_2','zuzi_3','zuzi_4','zuzi_5','zuzi_6','zuzi_7','zuzi_8','zuzi_9','zuzi_10']),
	unnest(array['mu1','mu1','mu2','mu2','mu2','mu2','mu2','mu3','mu3','mu3']),
	unnest(array[210,234,252,270,312,312,360,288,288,300])
	
--Для каждого дворника мы хотим увидеть:

-- - сколько дворников трудится в его мастерском участке (uchastok)
-- - чему равняется среднее количество часов, затраченных на работу в его мастерском участке
-- - на сколько процентов отклоняется его значение затраченных часов на работу в прошлом месяце 
-- от среднего значения по МУ
	
select *, count(dvornik) over (partition by uchastok) as dvrnk_cnt,
	round(avg(hours) over (partition by uchastok),0) as  hrs_avg,
	round(((hours - avg(hours) over (partition by uchastok))/avg(hours) over (partition by uchastok))*100,0) as diff
from zuzi_dvorniks

drop schema _mosinfo


-- Тестовое задание для стажеров
-- Задание №1
-- Использовать в качестве СУБД postgresql
create schema testy

set search_path to testy

create table work_types(
id integer primary key,
title varchar(100)
)

create table stickers(
id serial primary key,
title varchar(50)
)

create table tasks(
id serial primary key,
c varchar(100),
work_type_id integer references work_types(id),
date_created date not null default now()
)

create table files (
id serial primary key,
task_id integer not null references tasks(id),
sticker_id integer references stickers(id)
)

--я так понял, чтобы обойти ограничение not null в sticker_id принято решение 
-- не делать составной первичный ключ 

insert into work_types (id,title)
select unnest(array[100004027,100004028,100004029,100003926]),
	unnest(array['Снегопад. Содержание УЗ (1 день)','Снегопад. Содержание УЗ (2 день)','ЗСнегопад. Содержание УЗ (3 день)','Промывка ТПУ и ПЗ']
	)
	
select * from work_types

insert into stickers(title)
values ('ДО'),('ПОСЛЕ'),('Посев газона'),('Ракурс'),('Инструкция')

select * from stickers

-- Таблицы tasks и files необходимо заполнить самостоятельно для 
-- демонстрации результата

insert into tasks (title,work_type_id,date_created)
values ('уборка',100004027,'2022-02-01')

select * 
from tasks
where work_type_id = 100004027

insert into tasks (title,work_type_id,date_created)
values ('ремонт',100004027,'2022-02-07'),('погрузка',100004028,'2022-02-09'),
	('очистка',100004027,'2022-02-13'),('заливка',100004029,'2022-02-05'),
	('покраска',100003926,'2022-02-07')
	
select *
from tasks t 


insert into files (task_id, sticker_id)
values (1,1),(1,2),(1,3),(1,null),(1,null),
	(2,1),(2,2),(2,null),(2,null),(2,5),
	(3,1),(3,2),(3,3),(3,4),(3,null),
	(4,1),(4,null),(4,null),(4,null),(4,5),
	(5,1),(5,null),(5,null),(5,4),(5,5),
	(6,null),(6,2),(6,3),(6,null),(6,5)
	
select * from files

-- Вывести 4 колонки: tasks.id, tasks.title, кол-во ракурсов и кол-во фото
--(все кроме ракурсов и инструкций) заданий типа "Снегопад. Содержание УЗ (1 день)"
-- с 1-7 февраля текущего года.
-- Поле sticker_id может содрежать значение null 
--и его необходимо учитывать при формировании 4 колонки

select y.id,y.title, count(f.id) filter (where s.title='ракурс') over (partition by y.id) as "кол-во ракурсов",
	count(f.id) filter (where s.title='ДО' or s.title='ПОСЛЕ' or s.title='Посев газона') over (partition by y.id) as "кол-во фото"
from 
	(select t.id,t.title 
	from tasks t 
	join work_types wt on t.work_type_id = wt.id 
	where (t.date_created between '2022-02-01' and '2022-02-07') and (wt.title ='Снегопад. Содержание УЗ (1 день)')) y
join files f on f.task_id = y.id
join stickers s on s.id = f.sticker_id 

-- ракурсов не оказалось в данной выборке
-- что касается фото, которые еще не были загружены (со значением NULL)
-- я не до конца понял, что значит их учитывать