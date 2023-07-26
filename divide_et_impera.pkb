create or replace package body divide_et_impera as
----------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------
  type t_ora_name_c is table of varchar2(30 char);
----------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------
  function breakdown(
      i_source_code in clob)
    return breakdown_c pipelined
  is
    txt constant clob not null:=i_source_code;
    eol constant character(1 char):=chr(10);
    trg constant t_ora_name_c:=t_ora_name_c('PROCEDURE','PACKAGE','FUNCTION');
    okw constant t_ora_name_c:=t_ora_name_c('CREATE','OR','REPLACE','AS','IS','BEGIN','END','RETURN',
                                            'INTEGER','VARCHAR2','NUMBER','DATE')
                               multiset union trg;
    idx integer:=0;
    ccr character(1 char);  -- current character
    lst character(1 char);  -- last character
    isc boolean:=false;     -- is comment
    isi boolean:=false;     -- is ident (previously piped)
    wrd varchar2(4000 char);  -- word found/concatenated
    rix integer:=0;
    ---
    function prow return breakdown_r is
      l_cat dbms_id_128;
    begin
      rix:=rix+1;
      case 
        when upper(rtrim(wrd,eol)) member of trg 
          then l_cat:='IDEN';
               isi:=true;
        when isi
          then l_cat:='NAME';
               isi:=false;
        when upper(rtrim(wrd,eol)) member of okw 
          then l_cat:='KEYW';
        when isc
          then l_cat:='COMM';
          else l_cat:='CODE';
       end case;
      return breakdown_r(rix, 
                         l_cat,
                         case when l_cat in ('IDEN','NAME')
                          then upper(rtrim(rtrim(rtrim(wrd,eol),';'),'('))
                          else rtrim(wrd,eol)
                         end);
    end;
  begin
    while idx<length(txt) loop
      idx:=idx+1;
      lst:=ccr;
      ccr:=substr(txt,idx,1);
      
        -- end of line is reset and break out loop
        if ccr=eol and wrd is null then
          wrd:=null;
          isc:=false;
          continue;
        end if;
  
        -- mark comment lines
        if ccr||lst='--' then
          isc:=true;
        end if;
      
      -- concat characters to words
      if ccr!=' ' or isc then
        wrd:=wrd||ccr;
      end if;
      
      if (ccr=' ' and not isc) or ccr=eol then 
        if wrd is not null then
          pipe row(prow); 
        end if;
        wrd:=null;
        isc:=false;
      end if;
  
    end loop;  
  
  
    --eturn breakdown_c( breakdown_r(9, 'a', 'B') );
--    pipe row ( breakdown_r(9, 'a', 'B') );
  end breakdown;
----------------------------------------------------------------------------------------------------------------------------------------------------------------
  function parse_result(
      i_source_code in clob)
    return parse_result_c pipelined
  is
    l_row parse_result_r:=parse_result_r(null, null, 0, null, null, null, null);
    idx integer:=0;
    isp boolean:=false;
  begin
    for i in (
      select parse_category as cty, parse_string as str from breakdown_f() where parse_category in ('IDEN','NAME','COMM') or lower(parse_string)='as'
      order by parse_order
    ) loop
--      if l_row is null then
--        l_row:=parse_result_r(null, null, idx, null, null, null, null);
--        idx:=idx+1;
--      end if;
  
      case i.cty
        when 'NAME' then
          l_row.obj_name:=i.str;
          if not isp then
            pipe row(l_row);
            l_row:=null;
          end if;
        when 'IDEN' then
          l_row.obj_type:=i.str;
          -- special modus
          isp:=i.str='PACKAGE';
        when 'COMM' then
          -- hier verzweigung ob @ oder > oder einfacher nicht beachtender kommentar...
          l_row.obj_annotation:=l_row.obj_annotation||i.str;
      else
        isp:=not lower(i.str)='as';
          pipe row(l_row);
          l_row:=null;
      end case;
    
    end loop;  
  end parse_result;
----------------------------------------------------------------------------------------------------------------------------------------------------------------



--  
--  
--  function seconds_since(i_start_time in timestamp with time zone)
--    return number
--  is
--    c_beg constant timestamp not null:=i_start_time;
--    c_end constant timestamp not null:=current_timestamp;
--  begin
--    return
--      round(
--        extract(day    from(c_end-c_beg)) * 24 * 60 * 60 +
--        extract(hour   from(c_end-c_beg))      * 60 * 60 +
--        extract(minute from(c_end-c_beg))           * 60 +
--        extract(second from(c_end-c_beg))
--        ,3);
--  end seconds_since;
------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  procedure exc(i_arid    in  integer,
--                i_user    in  varchar2,
--                o_results out rule_result_c,
--                o_details out string_c )
--  is
--    c_max_bulk  constant pls_integer:=1000;
--    c_time_beg  constant timestamp:=current_timestamp;
--    c_arid      constant analyzer_rules.arid%type not null := i_arid;
--    c_user_name constant dbms_id_30 not null := i_user;
--    l_stmt      analyzer_rules.verification_sql%type;
--    l_rule_cfg analyzer_rules%rowtype;
--    l_cur       sys_refcursor;
--    l_out       rule_result_c;
--  begin
--    select * into l_rule_cfg from analyzer_rules where arid=c_arid;
--    l_stmt:=l_rule_cfg.verification_sql;
--
--    -- inject object_type
----    l_stmt:=regexp_replace(l_stmt, 'select', 'select rule_result_o(', 1, 1, 'i');
----    l_stmt:=regexp_replace(l_stmt, 'from', ') from', 1, 1, 'i');
--    
--    -- open cursor with or without bind variable
--    case regexp_count(upper(l_stmt),':OWNER')
--      when 1 then open l_cur for l_stmt using i_user;
--      when 2 then open l_cur for l_stmt using i_user, i_user;
--      --when 3...
--      else open l_cur for l_stmt;
--    end case;
--      loop
--        fetch l_cur bulk collect into l_out limit c_max_bulk;
--        exit when l_cur%notfound;
--      end loop;
--    close l_cur;
--    
--    o_results:=l_out;  
--
--    o_details:=string_c('OCC-'||c_arid||' '||l_rule_cfg.title||' ['||seconds_since(c_time_beg)||' sec]'||case when l_out.count>0 then ' (FAILED)'end);
--    
--    for i in 1..l_out.count loop
--      o_details.extend();
--      o_details(i+1):='  '||l_out(i).level1_name;
--    end loop;
--  exception
--    when others then
--      if l_cur%isopen then close l_cur; end if;
--      raise;
--  end exc;
----------------------------------------------------------------------------------------------------------------------------------------------------------------
end divide_et_impera;
/
