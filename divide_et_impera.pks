create or replace package divide_et_impera authid definer as

  type breakdown_r is record(
    parse_order     integer,
    parse_category  varchar2(4 char),
    parse_string    varchar2(400 char)
  );
  type breakdown_c is table of breakdown_r;

  -- first step
  /*
  select * from divide_et_impera.breakdown('create or replace package testparser 
-- zeile 1
-- und zeile 2
-- und 3...

as


-- den hier nicht

  --> Wunderbar,
  -- geht es über mehrere Zeilen.
  procedure
  do_it_well;
 
  --> Kurze Beschreibung. 
  --@ Parameter 1
  -- ist toll.
  function how_much_is_IT (
    a_eins in number,
    b_zwei in number) return integer;

end testparser;')
where parse_category in ('IDEN','NAME','COMM') or lower(parse_string)='as';
;
  */
  function breakdown(
      i_source_code in clob)
    return breakdown_c pipelined;

  ---

  type parse_result_r is record(
    obj_type                       varchar2(30 char),
    obj_name                       varchar2(128 char),
    obj_index                      integer,
    obj_annotation                 varchar2(4000 char),
    data_type                      varchar2(30 char),
    comma_sep_parameter_annotation varchar2(4000 char),
    example_usage                  varchar2(4000 char)
  );
  type parse_result_c is table of parse_result_r;

  -- second step
  /*
  select * from divide_et_impera.parse_result('create or replace package testparser 
  -- zeile 1
  -- und zeile 2
  
  
  as
  
  
  -- den hier nicht
  
    --> Wunderbar,
    -- geht es über mehrere Zeilen.
    procedure
    do_it_well;
   
    --> Kurze Beschreibung. 
    --@ Parameter 1
    -- ist toll.
    function how_much_is_IT (
      a_eins in number,
      b_zwei in number) return integer;
  
  end testparser;')
  */
  function parse_result(
      i_source_code in clob)
    return parse_result_c pipelined;
  
end divide_et_impera;
/
