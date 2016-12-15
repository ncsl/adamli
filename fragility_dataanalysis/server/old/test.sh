# patients listed 5 per row
patients=('pt1sz2' 'pt1sz3' 'pt2sz1' 'pt2sz3' 'pt7sz19'\
 'pt7sz21' 'pt7sz22' 'JH105sz1' 'EZT005seiz001' 'EZT005seiz002'\
 'EZT007seiz001' 'EZT007seiz002' 'EZT019seiz001' 'EZT019seiz002' 'EZT045seiz001'\
 'EZT045seiz002' 'EZT090seiz002' 'EZT090seiz003')
echo ${#patients[@]}

for proc in `seq 0 ${#patients[@]}`; do
	patient=${patients[proc]}
	echo $proc
	echo $patient
done
wait