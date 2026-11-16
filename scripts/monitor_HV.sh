for fc in 1 2 3; do
    caget \
      "SFRS:FHF1:MUSIC1:FC${fc}:NHV:V_RBV" \
      "SFRS:FHF1:MUSIC1:FC${fc}:NHV:I_RBV" \
      "SFRS:FHF1:MUSIC1:FC${fc}:NHV:V_SET" \
      "SFRS:FHF1:MUSIC1:FC${fc}:NHV:I_SET" \
      "SFRS:FHF1:MUSIC1:FC${fc}:NHV:STATUS"
done

