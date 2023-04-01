********************************************************************************
*******       LIMPIEZA INDICADORES DE POBREZA MULTIDIMENSIONAL   ***************
********************************************************************************

*Andrea Clavo 

global intermedias "G:\Mi unidad\C2022 -2\QLAB - DIPLOMADO\4_Rstudio_Intermedia\Trabajo final\Muestras\Intermedias/"

global output 		"G:\Mi unidad\C2022 -2\QLAB - DIPLOMADO\4_Rstudio_Intermedia\Trabajo final\Muestras\Outputs/"

global input "G:\Mi unidad\C2022 -2\QLAB - DIPLOMADO\4_Rstudio_Intermedia\Trabajo final\Muestras\Inputs/"



forvalue j = 17/21 {


**EDUCACION
**************
*p300n p300i p301a p301b p301c

*ABRIR MODULO 300 DE EDUCACION
use "${input}20`j'/enaho01a-20`j'-300.dta", clear

*Escolaridad del jefe de hogar
*Es 1 si es que tiene secundaria incompleta 
gen     escol_jefe=0 
replace escol_jefe=1 if p203==1 & p301a<=5

*Matricula escolar: 7-18
*Es 1 si es que tiene edad escolar y no está cursando y no terminó la escuela
gen       matri_esc=0
replace   matri_esc=1 if (p208a>6 & p208a<=14) & p306==2 & p301a<=5

collapse (sum) escol_jefe matri_esc  , by(conglome vivienda hogar factor07)

*del anterior-matricula escolar, calificar cada hogar con 0 y 1 solamente
replace matri_esc=1 if matri_esc>=1

save    "${input}20`j'/educacion_20`j'.dta", replace


**SALUD
**ABRIR MODULO 400 DE SALUD
use  "${input}20`j'/enaho01a-20`j'-400.dta", clear

*ASISTENCIA A CENTRO DE SALUD
*p4021-p4024: en las ultimas semanas presento malestar, enfermedad, recaida o accidente 
gen     malestar= p4021 + p4022 + p4023 + p4024
**se recodifica los missing con cero
recode  malestar (mis=0)
**se recodifica la variable para que tome valor 0 o 1
replace malestar=1 if malestar>=1

*RAZONES POR LAS QUE NO ACUDIO AL CENTRO DE SALUD
*p4091 (no tuvo dinero), p4092 (se encuentra lejos) & p4097 (no tiene seguro)
recode  p4091 p4092 p4097(mis=0)
gen       razones= p4091 + p4092 + p4097
replace razones=1 if razones>=1
gen       salud_asist=0

*Variable que indica que no fue atendido por alguna razon de precariedad 
replace salud_asist=1 if malestar==1 & razones==1


*NO CUENTA CON NINGUN TIPO DE SEGURO 
gen no_seguro = p4191 == 2 & p4192 == 2 & p4193 == 2 & p4194 == 2 & p4195 == 2 & p4196 == 2 & p4197 == 2 & p4198 == 2

*DE INDIVIDUOS A HOGARES
collapse (sum) salud_asist no_seguro , by(conglome vivienda hogar factor07)
*del anterior-asistio a centro de salud, calificar cada hogar con 0 y 1 solamente
replace salud_asist=1 if salud_asist>=1
replace no_seguro = 1 if no_seguro >= 1
save "${input}20`j'/salud_20`j'.dta", replace


**VIVIENDA
**ABRIR MODULO 100 VIVIENDA
use  "${input}20`j'/enaho01-20`j'-100.dta", clear
*limpiar los registros incompletos
tab     result
drop if result>=3
*se borro los registros rechazo ausentes desocupada vivienda otro

*PISO DE LA VIVIENDA
recode  p103 (mis=7)
gen     pisos=0
replace pisos=1 if p103>=6

*AGUA NO POTABLE
gen     agua=0
replace agua=1 if p110>=4
replace agua=1 if agua == 0 & p110a1 == 2

*SERVICIO HIGIENICO INADECUADO 
gen     desague=0
replace desague=1 if p111>= 5 

*ALUMBRADO: NO ES ELECTRICIDAD
gen     electricidad=0
replace electricidad=1 if p1121!=1

*COMBUSTIBLE USADO NO ADECUADO 
gen     comb_coc=0
replace comb_coc=1 if p113a>=5

save     "${input}20`j'/vivienda_20`j'.dta", replace


** EQUIPAMIENTO DEL HOGAR 
use  "${input}20`j'/enaho01-20`j'-612.dta", clear 

*NO CUENTA CON radio, tv, telefono, compu, bici, moto, refrigerador, auto, camion. 
gen auto = p612n == 17 
gen bien = 0
	foreach i in 1 2 3 7 16 18 12 {
	replace bien = 1 if p612n == `i'
	}

*Tiene bienes, tiene autos 
gen bienes = p612 == 1 & bien == 1 
gen autos = p612 == 1 & auto == 1 


*A NIVEL DE HOGAR 
collapse(sum)  bienes autos, by(conglome vivienda hogar factor07 ubigeo )

gen bien =  autos == 0 & bienes <= 1 
drop autos bienes

save "${input}20`j'/equipamiento_20`j'.dta", replace 

***Unimos las bases vivienda, salud y educacion
use  "${input}20`j'/sumaria-20`j'.dta", clear
merge 1:1  conglome vivienda hogar using "${input}20`j'/vivienda_20`j'.dta", nogenerate
merge 1:1  conglome vivienda hogar using "${input}20`j'/salud_20`j'.dta", nogenerate
merge 1:1  conglome vivienda hogar using "${input}20`j'/educacion_20`j'.dta", nogenerate
merge 1:1  conglome vivienda hogar using "${input}20`j'/equipamiento_20`j'.dta", nogenerate

*se renombro año, por los caracteres
rename a*o año

*Base de datos por Hogares
*llevar hogares a personas
gen facpobmie=factor07*mieperho


*VARIABLE DEPARTAMENTO
destring ubigeo, generate(dpto)
replace dpto=dpto/10000
replace dpto=round(dpto)
label variable dpto "Departamento"
label define dpto 1 "Amazonas"
label define dpto 2 "Ancash", add
label define dpto 3 "Apurimac", add
label define dpto 4 "Arequipa", add
label define dpto 5 "Ayacucho", add
label define dpto 6 "Cajamarca", add
label define dpto 7 "Callao", add
label define dpto 8 "Cusco", add
label define dpto 9 "Huancavelica", add
label define dpto 10 "Huanuco", add
label define dpto 11 "Ica", add
label define dpto 12 "Junin", add
label define dpto 13 "La_Libertad", add
label define dpto 14 "Lambayeque", add
label define dpto 15 "Lima", add
label define dpto 16 "Loreto", add
label define dpto 17 "Madre_de_Dios", add
label define dpto 18 "Moquegua", add
label define dpto 19 "Pasco", add
label define dpto 20 "Piura", add
label define dpto 21 "Puno", add
label define dpto 22 "San_Martin", add
label define dpto 23 "Tacna", add
label define dpto 24 "Tumbes", add
label define dpto 25 "Ucayali", add
label values dpto dpto

*NOS QUEDAMOS CON LA VARIABLES DE INTERES

keep año conglome vivienda hogar estrato ubigeo dpto dominio mieperho totmieho percepho facpobmie bien matri_esc escol_jefe no_seguro salud_asist comb_coc electricidad desague agua pisos bien 

*usando el comando svyset para obtener el error estandar y el intervalo de confianza
svyset [pweight=facpobmie], psu(conglome) strata(estrato)
collapse pisos-bien [pweight=facpobmie], by(dpto)


save "${input}20`j'/base_20`j'.dta", replace 

}


*svy:mean pisos-bien, over(dpto)
*xsvmat, from(r(table)')  names(col)   norestore



