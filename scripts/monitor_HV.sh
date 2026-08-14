for fc in 1 2 3; do
    caget \
      "SFRS:FHF1:MUSIC1:FC${fc}:HV_V_RBV" \
      "SFRS:FHF1:MUSIC1:FC${fc}:HV_I_RBV" \
      "SFRS:FHF1:MUSIC1:FC${fc}:HV_V_SET" \
      "SFRS:FHF1:MUSIC1:FC${fc}:HV_I_SET" \
      "SFRS:FHF1:MUSIC1:FC${fc}:HV_STATE"
done

