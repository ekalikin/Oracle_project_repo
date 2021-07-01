create or replace FUNCTION get_tab_ptf ( p_row NUMBER) RETURN t_tf_tab PIPELINED AS
--l_tab t_tf_tab := t_tf_tab();
BEGIN
for i IN 1..p_row LOOP
--l_tab.extend;
PIPE ROW( t_tf_row(i, 'Description for '|| i));
END LOOP;
RETURN ;
END;
