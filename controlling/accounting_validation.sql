/*****************************************************************

SQL validation triggers restricting/removing the possibility to
update the tables account_move and account_move_line after an
entry has been posted.

******************************************************************/


CREATE OR REPLACE FUNCTION account_move_verify_update()
  RETURNS trigger AS
$$
BEGIN
  if OLD.write_uid = 1 THEN
    raise exception 'The admin role is restriced from making journal entries';
  end if;
  
  if OLD.state like 'posted' THEN
  
    case  
      when NEW.name <> OLD.name then
        raise exception 'The label (name) cannot be updated after entry has been posted';
     
      when NEW.ref <> OLD.ref then
        if NEW.ref <> NEW.name then
          raise exception 'The reference cannot be changed on a posted entry 
          ref -> % - %,
          name -> % - %', OLD.ref, NEW.ref, OLD.name, NEW.name
          using hint = 'Update existing record is restricted.';
        end if;
        
      when NEW.date <> OLD.date then
        raise exception 'The date cannot be changed on a posted entry
        date -> %s - %s', OLD.date, NEW.date
        using hint = 'Update existing record is restricted.';
        
      when NEW.partner_id <> OLD.partner_id then
        raise exception 'The partner cannot be changed on a posted entry';
  
      else
        return NEW;

    end case;
  
  END IF;
 
 RETURN NEW;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION account_move_line_verify_update()
  RETURNS trigger AS 
$$
BEGIN
  if 'posted' in (select state from account_move where account_move.id = OLD.move_id) THEN
    case
      when NEW.debit <> OLD.debit or NEW.credit <> OLD.credit then
        raise exception 'The amount cannot be changed on a posted entry';
      when NEW.account_id <> OLD.account_id then
        raise exception 'The account cannot be changed on a posted entry';        
      when NEW.partner_id <> OLD.partner_id then
        raise exception 'The partner cannot be changed on a posted entry';
      when NEW.name <> OLD.name then
        if OLD.ref <> NEW.name then
          raise exception 'The label (name) cannot be updated after entry has been posted 
          ref -> % - %,
          name -> % - %', OLD.ref, NEW.ref, OLD.name, NEW.name
          using hint = 'Update existing record is restricted.';
        end if;
        
      else
        return NEW;

    end case;
  
  END IF;
 
 RETURN NEW;
END;
$$
LANGUAGE plpgsql;


CREATE TRIGGER trg_account_move_line_on_update
  BEFORE UPDATE
  ON account_move_line
  FOR EACH ROW
  EXECUTE PROCEDURE account_move_line_verify_update();


CREATE TRIGGER trg_account_move_on_update
  BEFORE UPDATE
  ON account_move
  FOR EACH ROW
  EXECUTE PROCEDURE account_move_verify_update();
