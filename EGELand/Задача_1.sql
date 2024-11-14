/*отдельно в СТЕ считаю количество сделанных домашних заданий, 
 * чтобы не тащить эти джойны в итоговую таблицу*/
with homework_count as (
    Select 
        hd.user_id,
        cu.course_id,
        count(distinct hd.homework_id) as count_homework_done
    from homework_done hd
    left join homework_lessons hl on hl.homework_id = hd.homework_id
    left join lessons l on l.id = hl.lesson_id
    left join course_users cu on cu.user_id = hd.user_id and l.course_id = cu.course_id
    group by hd.user_id, cu.course_id 
)  

/*строю итоговую таблицу*/
Select --отбираем нужные столбцы и переименовываем
       cu.course_id, 
       c.name as name_courses, 
       sub.name as name_subjects, 
       sub.project as type_subjects,
       /*нужны только годовые курсы, поэтому сразу пропишем тип, 
        * чтобы не джойнить лишнюю таблицу*/
       'Годовой' as type_courses, 
       c.starts_at as start_date, 
       cu.user_id, 
       us.last_name, 
       ci.name as city_name,
       cu.active, 
       /*из схемы не понятно, какая дата отвечает 
       за открытие курса, выбрал наиболее подходящую дату по логике,
        где обновляется число открытых уроков*/
       cu.updated_at as date_opening,
       /*считаю количество открытых месяцев исходя из количества открытых уроков пользователя
        * и количества уровок на курсе и округляю до целого вниз*/
       coalesce(floor(available_lessons/lessons_in_month), 0) as full_available_month,  
       /*из СТЕ добавляем количество сделанных домашних заданий*/
       coalesce(hc.count_homework_done, 0) AS total_homework_done 

From users us 
/*джоины таблиц по схеме БД*/
left join course_users cu on us.id = cu.user_id
left join courses c on cu.course_id = c.id
left join subjects sub on sub.id = c.subject_id 
left join cities ci on ci.id = us.city_id
/*из СТЕ джоним количество сделанных домашних*/
left join homework_count hc ON hc.user_id = cu.user_id AND hc.course_id = cu.course_id 
/*далее отбор не пустых user id, типов курсов - годовые, 
 * типов предметов - ЕГЭ/ОГЭ, а также юзера с типом роли - студент*/
where us.id is not null
and c.course_type_id in (select course_types.id
                          from course_types 
                          where name ilike 'Годовой%')
and sub.project in ('ЕГЭ', 'ОГЭ')
and us.user_role_id in (select user_roles.id
                    from user_roles
                    where name = 'student')