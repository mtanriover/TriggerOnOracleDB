DROP TRIGGER SCHEMA.WHEN_PAYMENT;

CREATE OR REPLACE TRIGGER SCHEMA.WHEN_PAYMENT;
   AFTER INSERT ON schema.payments
   FOR EACH ROW
DECLARE
   ll_borctan_kesme number;
   ll_bsu_donem_no long;
   ll_abone_no long;
   ll_bsu_ariza_no long;
   ll_tutar decimal(5,2);
   ll_tam_odeme boolean;
   ll_kapama_turu char;
   ll_tutanak char;
   ll_acma_kesme number;
  
BEGIN
    IF  (:new.bgp_gelirkod_no = 25159 and :new.turu in ('N','M')) THEN   --Does the subject of the payment belong to the terminated water service?   
     
        select COUNT(NO) INTO ll_borctan_kesme from bsu_ariza --Is there an active record in the water service termination table?
        where islem_turu='3' 
        and islemtar in (select max(a.islemtar) from bsu_ariza a where a.bsu_beyan_no = bsu_ariza.bsu_beyan_no)
        AND bsu_beyan_no = :new.bgs_beyan_no;
        
        select tahakkuk_tutari into ll_tutar from bgs_tahak where no = :new.bgs_tahak_no;
        
        select 
            member_no, condition, report, service_status
        into
            ll_abone_no, ll_kapama_turu, ll_tutanak, ll_acma_kesme
        from bsu_beyan_table where no = :new.bgs_members_no; --get some info of water subscription record
        
        IF ll_tutar = :new.tutar THEN --Has the terminated water service fee been paid in full?
        ll_tam_odeme:=true;
        END IF;
    
   
    
        if (((ll_borctan_kesme > 0) or (ll_tutanak='H' and ll_acma_kesme='8')) and ll_kapama_turu = 'A' and ll_tam_odeme) then --Are all conditions met for the water service to be active again?
        
            select max(no) into ll_bsu_donem_no from bsu_donem where aktif='E'; --get active period
                        
            SELECT bsu_xxxx_no.NEXTVAL INTO ll_bsu_ariza_no FROM DUAL; --get sequence for insert data to table
            
            insert into bsu_ariza --start record entry to the job tracking screen table of the field teams
            (
            no, 
            bsu_beyan_no, 
            bsu_donem_no, 
            sbs_muhatap_no, 
            bsu_arizatur_no, 
            bildirim_tarihi, 
            bil_aciklama, 
            sis_kullanici_no, 
            islemtar, 
            tahakkuk_olustur, 
            islem_turu, 
            numarataj, 
            bildirim_saati, 
            tutanak,
            kacak_kullanim
            )
            values
            (
            ll_bsu_ariza_no,
            :new.bgs_beyan_no,
            ll_bsu_donem_no,
            :new.sbs_muhatap_no,
            0,
            to_date(SYSDATE),
            'Tahsilat sonucu otomatik olusan is emri',
            0,
            SYSDATE,
            'H',
            1,
            ll_abone_no,
            TO_CHAR(SYSDATE,'HH24'),
            'H',
            'H'        
            ); -- after insert; the technical staff, who sees this record on the job tracking screen, sees that the water subscriber has paid her debt and removes the seal on the water valve so that she can get the water service again.
        else
        return;
        end if;
        
      else
        return;
    
     END IF;  

      else
        return;
    
     END IF;  
        
END WHEN_PAYMENT;
/