DROP TRIGGER db.trigger_name;

CREATE OR REPLACE TRIGGER db.trigger_name
   AFTER INSERT 
   ON db.bgs_tahsil
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
   ll_bolge_no number;
   ll_mesai_ici_sis_kullanici number;
   ll_mesai_disi_sis_kullanici number;
   ll_sonraki_gun_sis_kullanici number;
   ll_is_atanan_sis_kullanici number;
   ll_bsu_ekip_no number;
   ll_bsu_sms_sonuc LONG;
   ll_borc_tutari decimal(12,2);
   
BEGIN
    IF  (:new.bgp_gelirkod_no = 25159 and :new.turu in ('N','M')) THEN   --BORÇTAN KESME TAHSİL EDİLDİĞİNDE BORÇTAN KESME İŞ EMRİNİ KONTROL ET...    
     
        select COUNT(NO) INTO ll_borctan_kesme from bsu_ariza 
        where islem_turu='3' 
        and islemtar in (select max(a.islemtar) from bsu_ariza a where a.bsu_beyan_no = bsu_ariza.bsu_beyan_no)
        AND bsu_beyan_no = :new.bgs_beyan_no;
        
        select tahakkuk_tutari into ll_tutar from bgs_tahak where no = :new.bgs_tahak_no;
        
        --ÖDEME YAPILDIĞI GÜN İTİBARIYLA VADESİ GELMİŞ VE GEÇMİŞ BORÇLARI VAR MI? 
        
        ll_borc_tutari:=0;
        
        select coalesce(sum(borc_tutari),0) into ll_borc_tutari from bgs_tahak where kapama_turu='A' and to_date(vade_tarihi) <= to_date(sysdate) and bgs_beyan_no = :new.bgs_beyan_no;              
        
        select 
            numarataj, kapama_turu, tutanak, acma_kesme, (select coalesce(bsu_bolge_no,0) from bsu_defter where no in (select a.bsu_defter_no from bsu_beyan a where a.no = bsu_beyan.no))
        into
            ll_abone_no, ll_kapama_turu, ll_tutanak, ll_acma_kesme, ll_bolge_no
        from bsu_beyan where no = :new.bgs_beyan_no; --- ABONE NO BUL
        
        IF ll_tutar = :new.tutar THEN ---BORÇTAN KESME ÜCRETİNİN TAMAMI ÖDENDİ Mİ?
        ll_tam_odeme:=true;
        END IF;
    
   
        if (((ll_borctan_kesme > 0) or (ll_tutanak='H' and ll_acma_kesme='8')) and ll_kapama_turu = 'A' and ll_tam_odeme ) then --KESME İŞ EMRİ VARSA VEYA SÖZLEŞME BORÇTAN KESİK VE TUTANAKSIZ İSE...
                
                ---- 5 DK. ARAYLA ÇALIŞACAK OLAN "BSU_OTO_BORCTAN_ACMA_OLUSTUR" PROSEDURU,ILGILI KAYITLARI "BSU_BORCTAN_ACMA_LOG" TABLOSUNDAN OKUYACAK
                INSERT INTO BSU_BORCTAN_ACMA_LOG 
                                                (
                                                BSU_BEYAN_NO, 
                                                ISLEMTAR , 
                                                VADESI_GECMIS_BORC , 
                                                BTS_VEZNE_NO, 
                                                ACILDI, 
                                                BSU_ARIZA_NO 
                                                )
                VALUES (:new.bgs_beyan_no, sysdate, ll_borc_tutari, :new.bts_vezne_no, 'H', 0 );        
            else
          return;
        end if;
        
      else
        return;
    
     END IF;  
        
END;
/
