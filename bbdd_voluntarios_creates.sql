create table tarea
(
    nombre_tarea varchar(40) not null,
    min_horas    numeric(6),
    id_tarea     varchar(10) not null
        constraint pk_tarea
            primary key,
    max_horas    numeric(6)
)
    with (autovacuum_enabled = true);

alter table tarea
    owner to postgres;

grant references, select on tarea to public;

create table voluntario
(
    nombre           varchar(20),
    apellido         varchar(25) not null,
    e_mail           varchar(40) not null,
    telefono         varchar(20),
    fecha_nacimiento date        not null,
    id_tarea         varchar(10) not null
        constraint fk_tarea_v
            references tarea,
    nro_voluntario   numeric(6)  not null
        constraint pk_voluntario
            primary key,
    horas_aportadas  numeric(8, 2)
        constraint chk_hs_ap
            check (horas_aportadas > (0)::numeric),
    porcentaje       numeric(2, 2),
    id_institucion   numeric(4),
    id_coordinador   numeric(6)
        constraint fk_coordinador
            references voluntario,
    constraint ck_horas_aportadas
        check ((horas_aportadas <= (24000)::numeric) AND (id_coordinador < (206)::numeric))
)
    with (autovacuum_enabled = true);

alter table voluntario
    owner to postgres;

create unique index emp_email_uk
    on voluntario (e_mail);

grant references, select on voluntario to public;

create table continente
(
    nombre_continente varchar(25),
    id_continente     numeric not null
        constraint pk_continente
            primary key
)
    with (autovacuum_enabled = true);

alter table continente
    owner to postgres;

grant references, select on continente to public;

create table pais
(
    nombre_pais   varchar(40),
    id_continente numeric not null
        constraint fk_continente
            references continente,
    id_pais       char(2) not null
        constraint pk_pais
            primary key
)
    with (autovacuum_enabled = true);

alter table pais
    owner to postgres;

create table direccion
(
    calle         varchar(40),
    codigo_postal varchar(12),
    ciudad        varchar(30) not null,
    provincia     varchar(25),
    id_pais       char(2)     not null
        constraint fk_pais
            references pais,
    id_direccion  numeric(4)  not null
        constraint pk_direccion
            primary key
)
    with (autovacuum_enabled = true);

alter table direccion
    owner to postgres;

grant references, select on direccion to public;

create table institucion
(
    nombre_institucion varchar(60) not null,
    id_director        numeric(6)
        constraint fk_director
            references voluntario,
    id_direccion       numeric(4)
        constraint fk_direccion
            references direccion,
    id_institucion     numeric(4)  not null
        constraint pk_institucion
            primary key
)
    with (autovacuum_enabled = true);

alter table institucion
    owner to postgres;

alter table voluntario
    add constraint fk_institucion_v
        foreign key (id_institucion) references institucion;

create table historico
(
    fecha_inicio   date        not null,
    nro_voluntario numeric(6)  not null
        constraint fk_voluntario_h
            references voluntario,
    fecha_fin      date        not null,
    id_tarea       varchar(10) not null
        constraint fk_tarea_h
            references tarea,
    id_institucion numeric(4)
        constraint fk_institucion_h
            references institucion,
    constraint pk_historico
        primary key (fecha_inicio, nro_voluntario),
    constraint historico_check
        check (fecha_fin > fecha_inicio)
)
    with (autovacuum_enabled = true);

alter table historico
    owner to postgres;

grant references, select on historico to public;

grant references, select on institucion to public;

grant references, select on pais to public;

