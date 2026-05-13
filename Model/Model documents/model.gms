
set
    group       "natural gas"    / g1*g8760 /,
    group1      "steel market"     / g1*g8760 /,
    group2      "DRI load"         / g1*g8760 /,
    group3      "grid withdraw"    / g1*g8760 /
;

scalar
    Sw_battery                   "switch to turn on battery"                    / 1 /,
    Sw_UC                        "switch to turn on unit commitment"            / 0 /,
    Sw_DRI_blend_hour            "switch to turn on hourly gas blend adjustment"  / 0 /,
    Sw_DRI_load_hour             "switch to turn on hourly DRI load adjustment"   / 0 /,
    Sw_adjusted_annual_emission  "switch to turn on adjusted annual emission"     / 0 /,
    Sw_flex_DRI                  "switch to turn on flexile DRI load"             / 1 /,
    Sw_flex_scrap                "switch to turn on flexile scrap ratio"          / 1 /,
    Sw_flex_steel_market         "switch to turn on flexile steel market"         / 1 /,
    Sw_gas_backup                "switch to turn on gas as backup"                / 1 /,
    Sw_grid_backup               "switch to turn on grid as backup"               / 1 /,
    Sw_flex_grid                 "switch to turn on flexile gird electricity blend, if 0, grid hourly should be fixed" / 1 /,
    Sw_flex_gas_blend            "switch to turn on flexile DRI gas blend option (if not, gas must be fixed)"     / 1 /,
    scrap_ratio                  "scrap available ratio"                        / 0.5 /,
    emission_cap                 / 1000000 /,
    carbon_price                 / 100 /
;

set
    hr          / hr1*hr24 /,
    d           / d1*d365 /,
    t           / t1*t8760 /
;   

set dt(d,t);
set tech / solar, wind /;

set r               "provincal power system"  / TS, HD, SZ, WH, BT /;
set year      / 2020, 2035, 2050 /;
set all_weather_year / 2014*2023 /;
set weather_year(all_weather_year) / 2016 /;
set tech_cost_change / electrolyzer, solar, wind, battery_power, battery_energy /;
set Cost_name 
    / Wind_cost,
      Solar_cost,
      Battery_cost,
      Electrolyzer_cost,
      Tank_cost,
      DRI_furnace_cost,
      EAF_furnace_cost,
      Iron_ore_cost,
      Scrap_cost,
      Gas_cost,
      Gird_power_cost,
      Other_material_unit_cost,
      IronLabor_unit_cost,
      SteelLabor_unit_cost,
      Total_cost /
;
set Cap_name 
    / wind,
      solar,
      Battery_power,
      Battery_energy,
      Electrolyzer,
      Tank,
      DRI_furnace,
      EAF_furnace /;
set Power_balance_name 
    / Solar,
      Wind,
      bat_discharge,
      bat_charge,
      grid,
      ELE_power,
      DRI_power,
      EAF_power,
      DRI_reheat_power,
      bat_sto /;
set H2_balance_name 
    / H2_gen,
      H2_discharge,
      H2_charge,
      DRI_H2,
      H2_sto /;
set DRI_balance_name 
    / DRI_gen,
      DRI_discharge,
      DRI_charge,
      EAF_DRI,
      DRI_from_H2,
      DRI_from_gas,
      DRI_sto /;
set Material_name 
    / Steel_gen,
      DRI_ironore,
      EAF_Scrap /;
set Commitment_name 
    / Commitment,
      Startup,
      Shutdown /;
set Uhours_name 
    / Electrolyzer,
      DRI,
      EAF /;
set emission_type
    / gas_emission,
      power_emission,
      emission /;
set Day_sum 
    / gen_daysum,
      H2_gen_daysum,
      DRI_gen_daysum,
      DRI_from_H2_daysum,
      DRI_from_gas_daysum,
      DRI_ironore_daysum,
      EAF_DRI_daysum,
      EAF_Scrap_daysum,
      Steel_gen_daysum /;
set group_sum 
    / gen_groupsum,
      H2_gen_groupsum,
      DRI_gen_groupsum,
      DRI_from_H2_groupsum,
      DRI_from_gas_groupsum,
      DRI_ironore_groupsum,
      EAF_DRI_groupsum,
      EAF_Scrap_groupsum,
      Steel_gen_groupsum /;
set LCOX_name 
    / LCOE,
      LCOE_wgrid,
      LCOH_Wh,
      LCOH_kg,
      LCOD,
      LCOS /;
set daysum_name / gen, H2_gen, DRI_gen, DRI_from_H2, DRI_from_gas, DRI_ironore, EAF_DRI, EAF_Scrap, Steel_gen /;

alias (t, tt);

dt(d,t) = yes$(ord(t) > 24*(ord(d)-1) and ord(t) <= 24*ord(d));

set map(t, hr, d);
map(t, hr, d)$(ord(t) = ord(hr) + (ord(d)-1)*24) = yes;

set
    t_group(group,t),
    t_group1(group1,t),
    t_group2(group2,t),
    t_group3(group3,t)
;

set i_all   "iterations for DRI (both load and gas blend)" / i1*i7 /;
set i(i_all)  "iterations for DRI (both load and gas blend)" / i1*i7 /;
set i1      "iterations for grid"          / i1*i7 /;
set i2      "iterations for demand"        / i1*i7 /;
set j       "iterations for grid EF"       / j1*j3 /;
set k       "iterations for grid power price" / k1*k5 /;
set l       "iterations for scrap ratio"   / l1*l7 /;
set m       "iterations for emission cap"  / m1*m8 /;

alias (i_all, ii_all);
alias (i, ii, iii);

Parameter
    gs(i)   "group size (number) for DRI" /
        i1 365, 
        i2 120, 
        i3 60, 
        i4 30, 
        i5 12, 
        i6 4, 
        i7 1 /

    gs1(i1) "group size (number) for grid" /
        i1 8760, 
        i2 1095, 
        i3 365, 
        i4 60, 
        i5 12, 
        i6 4, 
        i7 1 /

    gs2(i2) "group size (number) for demand" /
        i1 365, 
        i2 120, 
        i3 60, 
        i4 30, 
        i5 12, 
        i6 4, 
        i7 1 /
;

Parameter
    grid_emission_factor(j) "group size in iteration i" / 
        j1 1, 
        j2 0.5, 
        j3 0 /,
    grid_price_factor(k) "group size in iteration i" / 
        k1 1, 
        k2 1.5, 
        k3 2, 
        k4 4, 
        k5 10 /,
    scrap_ratio_table(l) "group size in iteration l" / 
        l1 0.0,
        l2 0.1,
        l3 0.2,
        l4 0.3,
        l5 0.4,
        l6 0.5,
        l7 0.6 /,
    emission_cap_table(m) "group size in iteration m" /
        m1 0,
        m2 20000,
        m3 50000,
        m4 100000,
        m5 200000,
        m6 500000,
        m7 1000000,
        m8 2000000 /
;

Parameter
    Maxoutput(t,tech)
    Maxoutput_all_weather_year(t,tech,weather_year)
    GENC(tech)
    Steel_DEMAND(t)
    Maxoutput_all_region(t,r,tech,all_weather_year)
    cost_table(tech_cost_change,year)
    Gridpower_unit_cost_all_zone(r)
    Gas_unit_cost_all_zone(r)
    Gridpower_unit_emission_all_zone(r)
;

scalar
    ELEC, TANKC, BAT_PC, BAT_EC, DRIC, EAFC,
    DRI_H2_CONSUMPTION, DRI_power_CONSUMPTION, DRI_ironore_CONSUMPTION,
    EAF_DRI_power_CONSUMPTION, EAF_Scrap_power_CONSUMPTION, DRI_reheat_power_CONSUMPTION,
    PtH   "55kWh/kg H2", DRI_gas_CONSUMPTION,
    RampDownRate, RampUpRate, UnitSize, MinUpTime, MinDownTime,
    Ironore_unit_cost, Scrap_unit_cost,
    Gridpower_unit_cost   "M RMB/MWh", Gas_unit_cost,
    Gridpower_unit_emission, Gas_unit_emission,
    charge_eff      / 0.92 /,
    discharge_eff   / 0.92 /,
    DRI_from_gas_max_ratio / 0.3 /,
    ELE_max_load    / 1.1 /,
    ELE_min_load    / 0.05 /,
    DRI_min_load    / 0.7 /,
    DRI_max_load    / 1 /,
    H2_min_store    / 0.1 /,
    Ramp_gas_mix    / 0.025 /,
    IronLabor_unit_cost, SteelLabor_unit_cost, Other_material_unit_cost
;

$CALL "GDXXRW DRI_EAF_input.xlsx output=DRI_EAF_input.gdx skipempty=0 trace=2 index=Index!a1"
$gdxin DRI_EAF_input.gdx
$load Maxoutput Steel_DEMAND Maxoutput_all_weather_year Maxoutput_all_region cost_table GENC ELEC TANKC BAT_PC BAT_EC DRIC EAFC 
$load DRI_H2_CONSUMPTION DRI_power_CONSUMPTION DRI_ironore_CONSUMPTION EAF_DRI_power_CONSUMPTION EAF_Scrap_power_CONSUMPTION 
$load      DRI_reheat_power_CONSUMPTION DRI_gas_CONSUMPTION RampDownRate RampUpRate UnitSize MinUpTime MinDownTime 
$load      Ironore_unit_cost Scrap_unit_cost PtH Gridpower_unit_cost Gas_unit_cost Gridpower_unit_emission Gas_unit_emission 
$load      IronLabor_unit_cost SteelLabor_unit_cost Other_material_unit_cost Gridpower_unit_cost_all_zone Gas_unit_cost_all_zone 
$load      Gridpower_unit_emission_all_zone
;

Positive Variables

    Power_cap(tech)           "unit kW"
    gen(t,weather_year,tech)   "unit MWh"
    grid(t,weather_year)
    z2(weather_year)
    z1(group3,weather_year)

    DRI_power(t,weather_year)
    EAF_power(t,weather_year)
    ELE_power(t,weather_year)
    DRI_reheat_power(t,weather_year)
    bat_discharge(t,weather_year)   "unit kW"
    bat_charge(t,weather_year)      "unit kW"
    bat_sto(t,weather_year)         "unit kW"
    Battery_penalty(t,weather_year)
    DRI_penalty(t,weather_year)
    H2_gen(t,weather_year)          "unit kg H2/hour"
    H2_sto(t,weather_year)          "unit kg H2 stored"
    H2_discharge(t,weather_year)
    H2_charge(t,weather_year)
    DRI_H2(t,weather_year)          "unit kg H2 consumed"
    DRI_gas(t,weather_year)
    DRIClusterCommitment(t,weather_year)
    DRIClusterStartup(t,weather_year)
    DRIClusterShutdown(t,weather_year)
    DRI_gen(t,weather_year)
    DRI_from_H2(t,weather_year)
    DRI_from_gas(t,weather_year)
    z(group,weather_year)
    z4(weather_year)
    DRI_sto(t,weather_year)
    DRI_discharge(t,weather_year)
    DRI_charge(t,weather_year)
    EAF_DRI(t,weather_year)
    z3(group2,weather_year)
    DRI_ironore(t,weather_year)
    EAF_Scrap(t,weather_year)
    Steel_gen(t,weather_year)
    bat_p_cap   "--GW--"
    bat_e_cap   "--GWh--"
    ele_cap, tank_cap, DRI_cap, EAF_cap
    gas_emission(t,weather_year)
    power_emission(t,weather_year)
    emission(t,weather_year)
    total_emission
    Wind_cost, Solar_cost, Power_cost, Electrolyzer_cost, Battery_cost, Tank_cost, DRI_furnace_cost, EAF_furnace_cost, Iron_ore_cost, Scrap_cost,
    Gird_power_cost, Gas_cost, IronLabor_cost, SteelLabor_cost, Other_material_cost, Battery_penalty_cost, DRI_penalty_cost
;

Variable
    Power_UtilizationHours(tech,weather_year)
    ELE_UtilizationHours(weather_year)
    DRI_UtilizationHours(weather_year)
    EAF_UtilizationHours(weather_year)
    cost_structure(Cost_name,weather_year)
    emission_table(t,emission_type,weather_year)
    capacity_table(cap_name)
    LCOX_table(LCOX_name,weather_year)
    TVC, TC_annual(weather_year), TC, Steelcost
    emission_relaxation(weather_year)
    Emission_cost(weather_year)
    Curt(t,weather_year,tech)
    total_Curt_rate(weather_year)
    Power_balance(t,weather_year,Power_balance_name)
    H2_balance(t,weather_year,H2_balance_name)
    DRI_balance(t,weather_year,DRI_balance_name)
    Material(t,weather_year,Material_name)
    Commitment(t,weather_year,Commitment_name)
    gen_daysum(d,weather_year)
    H2_gen_daysum(d,weather_year)
    DRI_gen_daysum(d,weather_year)
    DRI_from_H2_daysum(d,weather_year)
    DRI_from_gas_daysum(d,weather_year)
    DRI_ironore_daysum(d,weather_year)
    EAF_DRI_daysum(d,weather_year)
    EAF_Scrap_daysum(d,weather_year)
    Steel_gen_daysum(d,weather_year)
    daysum_table(d,weather_year,daysum_name)
    gen_groupsum(group,weather_year)
    H2_gen_groupsum(group,weather_year)
    DRI_gen_groupsum(group,weather_year)
    DRI_from_H2_groupsum(group,weather_year)
    DRI_from_gas_groupsum(group,weather_year)
    DRI_ironore_groupsum(group,weather_year)
    EAF_DRI_groupsum(group,weather_year)
    EAF_Scrap_groupsum(group,weather_year)
    Steel_gen_groupsum(group,weather_year)
    LCOE
    LCOE_wgrid
    LCOH_Wh
    LCOH_kg
    LCOD
    LCOS

;


* Equations
Equations
    eq_power_capacity
    eq_electricity_balance
    eq_electricity_blend
    eq_electricity_blend1
    eq_Battery_SOC1
    eq_Battery_SOC2
    eq_Battery_capacity1
    eq_Battery_capacity2
    eq_Battery_capacity3
    eq_Battery_capacity4
    eq_Battery_penalty
    eq_H2_SOC1
    eq_H2_SOC2
    eq_H2_Tank_capacity2
    eq_H2_Tank_capacity3
    eq_H2_balance
    eq_electrolyzer_Pmax
    eq_electrolyzer_Pmin
    eq_DRI_balance
    eq_DRI_capacity1
    eq_DRI_capacity2
    eq_DRI_SOC1
    eq_DRI_SOC2
    eq_EAF_capacity
    eq_Stoichiometry_electrolyzer
    eq_Stoichiometry_DRI_from_H2
    eq_Stoichiometry_DRI_from_gas
    eq_Stoichiometry_DRI1
    eq_Stoichiometry_DRI2
    eq_Stoichiometry_DRI3
    eq_Stoichiometry_EAF1
    eq_Stoichiometry_EAF2
    eq_DRI_gas_blend1
    eq_DRI_gas_blend2
    eq_DRI_gas_blend3
    eq_DRI_gas_blend4
    eq_DRI_gas_blend5
    eq_DRI_gas_blend6
    eq_DRI_gas_blend7
    eq_DRI_gas_blend8
    eq_DRI_gas_blend9
    eq_DRI_gas_blend10
    eq_DRI_gas_max
    eq_DRI_penalty
    eq_DRI_penalty1
    eq_scrap_flexibility1
    eq_scrap_flexibility2
    eq_DRI_no_flexibility
    eq_steel_market_flexibility1
    eq_steel_market_flexibility2
    eq_RampDown1_noUC
    eq_RampDown2_noUC
    eq_RampUp1_noUC
    eq_RampUp2_noUC
    eq_DRI_load
    eq_emission1
    eq_emission2
    eq_emission3
    eq_emission4
    eq_emission5
    eq_emission6
    eq_Solar_cost
    eq_Wind_cost
    eq_Power_cost
    eq_Electrolyzer_cost
    eq_Battery_cost
    eq_Tank_cost
    eq_DRI_furnace_cost
    eq_EAF_furnace_cost
    eq_Iron_ore_cost
    eq_Scrap_cost
    eq_Gird_power_cost
    eq_Gas_cost
    eq_IronLabor_cost
    eq_SteelLabor_cost
    eq_Other_material_cost
    eq_emission_cost
    eq_Battery_penalty_cost
    eq_DRI_penalty_cost
    eq_TC_variable                
    eq_TC_annual 
    eq_TC
    eq_TC_variable1                
    eq_TC_annual1 
    eq_TC1
    eq_switch_gas
    eq_switch_grid
    eq_gen_daysum
    eq_H2_gen_daysum
    eq_DRI_gen_daysum
    eq_DRI_from_H2_daysum
    eq_DRI_from_gas_daysum
    eq_DRI_ironore_daysum
    eq_EAF_DRI_daysum
    eq_EAF_Scrap_daysum
    eq_Steel_gen_daysum
    eq_gen_groupsum
    eq_H2_gen_groupsum
    eq_DRI_gen_groupsum
    eq_DRI_from_H2_groupsum
    eq_DRI_from_gas_groupsum
    eq_DRI_ironore_groupsum
    eq_EAF_DRI_groupsum
    eq_EAF_Scrap_groupsum
    eq_Steel_gen_groupsum
;

* Power capacity
eq_power_capacity(t,weather_year,tech)..
    gen(t,weather_year,tech) =l= Power_cap(tech) * Maxoutput_all_weather_year(t,tech,weather_year)
;

* Electricity balance
eq_electricity_balance(t,weather_year)$[Sw_battery]..
    sum(tech, gen(t,weather_year,tech))
    + bat_discharge(t,weather_year)
    - bat_charge(t,weather_year)
    + grid(t,weather_year)
    =e= ELE_power(t,weather_year)
      + DRI_power(t,weather_year)
      + EAF_power(t,weather_year)
      + DRI_reheat_power(t,weather_year)
;

* Grid stability
eq_electricity_blend(t,weather_year)$[(not Sw_UC) $ (not Sw_flex_grid)]..
    grid(t,weather_year) =e= z2(weather_year)
;
eq_electricity_blend1(group3,t,weather_year)$[t_group3(group3,t) $ (not Sw_UC) $ Sw_flex_grid]..
    grid(t,weather_year) =e= z1(group3,weather_year)
;

* Battery state of charge
eq_Battery_SOC1(t,weather_year)$[(ord(t)>1)$(Sw_battery)]..
    bat_sto(t,weather_year) =e= bat_sto(t-1,weather_year)
                          + charge_eff * bat_charge(t,weather_year)
                          - bat_discharge(t,weather_year) / discharge_eff
;
eq_Battery_SOC2(t,weather_year)$[(ord(t)=1)$(Sw_battery)]..
    bat_sto(t,weather_year) =e= bat_sto("t8760",weather_year)
                          + charge_eff * bat_charge(t,weather_year)
                          - bat_discharge(t,weather_year) / discharge_eff
;

* Battery capacity
eq_Battery_capacity1(t,weather_year)$[Sw_battery]..
    bat_sto(t,weather_year) =l= bat_e_cap
;
eq_Battery_capacity2(t,weather_year)$[Sw_battery]..
    bat_charge(t,weather_year) =l= bat_p_cap
;
eq_Battery_capacity3(t,weather_year)$[Sw_battery]..
    bat_discharge(t,weather_year) =l= bat_p_cap
;
eq_Battery_capacity4(t,weather_year)$[Sw_battery]..
    bat_charge(t,weather_year) + bat_discharge(t,weather_year) =l= bat_p_cap
;

* Battery penalty
eq_Battery_penalty(t,weather_year)$[Sw_battery]..
    Battery_penalty(t,weather_year) =e= bat_discharge(t,weather_year) * 0.0000001
;

* Hydrogen balance      
eq_H2_balance(t,weather_year)..
    H2_gen(t,weather_year)
    + H2_discharge(t,weather_year)
    - H2_charge(t,weather_year)
    =e= DRI_H2(t,weather_year)
;

* Electrolyzer capacity (Hydrogen)
eq_electrolyzer_Pmax(t,weather_year)..
    ELE_power(t,weather_year) =l= ele_cap * ELE_max_load
;
eq_electrolyzer_Pmin(t,weather_year)..
    ELE_power(t,weather_year) =g= ele_cap * ELE_min_load
;

* Hydrogen state of charge
eq_H2_SOC1(t,weather_year)$[ord(t)>1]..
    H2_sto(t,weather_year) =e= H2_sto(t-1,weather_year)
                        + H2_charge(t,weather_year)
                        - H2_discharge(t,weather_year)
;
eq_H2_SOC2(t,weather_year)$[ord(t)=1]..
    H2_sto(t,weather_year) =e= H2_sto("t8760",weather_year)
                        + H2_charge(t,weather_year)
                        - H2_discharge(t,weather_year)
;

* Hydrogen storage capacity
eq_H2_Tank_capacity2(t,weather_year)..
    H2_sto(t,weather_year) =g= tank_cap * H2_min_store
;
eq_H2_Tank_capacity3(t,weather_year)..
    H2_sto(t,weather_year) =l= tank_cap
;

* DRI balance      
eq_DRI_balance(t,weather_year)..
    DRI_gen(t,weather_year)
    + DRI_discharge(t,weather_year)
    - DRI_charge(t,weather_year)
    =e= EAF_DRI(t,weather_year)
;

* DRI capacity      
eq_DRI_capacity1(t,weather_year)..
    DRI_gen(t,weather_year) =l= DRI_cap * DRI_max_load
;
eq_DRI_capacity2(t,weather_year)..
    DRI_gen(t,weather_year) =g= DRI_cap * DRI_min_load
;

* DRI state of charge
eq_DRI_SOC1(t,weather_year)$[ord(t)>1]..
    DRI_sto(t,weather_year) =e= DRI_sto(t-1,weather_year)
                        + DRI_charge(t,weather_year)
                        - DRI_discharge(t,weather_year)
;
eq_DRI_SOC2(t,weather_year)$[ord(t)=1]..
    DRI_sto(t,weather_year) =e= DRI_sto("t8760",weather_year)
                        + DRI_charge(t,weather_year)
                        - DRI_discharge(t,weather_year)
;

* EAF capacity      
eq_EAF_capacity(t,weather_year)..
    Steel_gen(t,weather_year) =l= EAF_cap
;

* Stoichiometry balance of electrolyzer     
eq_Stoichiometry_electrolyzer(t,weather_year)..
    H2_gen(t,weather_year)*PtH =e= ELE_power(t,weather_year)
;

* Stoichiometry balance of DRI     
eq_Stoichiometry_DRI_from_H2(t,weather_year)..
    DRI_H2(t,weather_year)/DRI_H2_CONSUMPTION =e= DRI_from_H2(t,weather_year)
;
eq_Stoichiometry_DRI_from_gas(t,weather_year)..
    DRI_gas(t,weather_year)/DRI_gas_CONSUMPTION =e= DRI_from_gas(t,weather_year)
;
eq_Stoichiometry_DRI1(t,weather_year)..
    DRI_from_H2(t,weather_year) + DRI_from_gas(t,weather_year) =e= DRI_gen(t,weather_year)
;
eq_Stoichiometry_DRI2(t,weather_year)..
    DRI_power(t,weather_year)/DRI_power_CONSUMPTION =e= DRI_from_H2(t,weather_year)
;
eq_Stoichiometry_DRI3(t,weather_year)..
    DRI_ironore(t,weather_year)/DRI_ironore_CONSUMPTION =e= DRI_gen(t,weather_year)
;

* Stoichiometry balance of EAF
eq_Stoichiometry_EAF1(t,weather_year)..
    EAF_DRI(t,weather_year)*EAF_DRI_power_CONSUMPTION
    + EAF_Scrap(t,weather_year)*EAF_Scrap_power_CONSUMPTION
    =e= EAF_power(t,weather_year)
;
eq_Stoichiometry_EAF2(t,weather_year)..
    (EAF_DRI(t,weather_year)*0.92 + EAF_Scrap(t,weather_year)*0.93)*0.95
    =e= Steel_gen(t,weather_year)*0.98
;

* DRI gas composition ramp hourly
eq_DRI_gas_blend1(t,weather_year)$[(ord(t)>1)$(not Sw_UC) $ Sw_flex_gas_blend $ Sw_DRI_blend_hour]..
    DRI_from_H2(t-1,weather_year) - DRI_from_H2(t,weather_year) =l= Ramp_gas_mix * DRI_cap
;
eq_DRI_gas_blend2(t,weather_year)$[(ord(t)=1)$(not Sw_UC) $ Sw_flex_gas_blend $ Sw_DRI_blend_hour]..
    DRI_from_H2("t8760",weather_year) - DRI_from_H2(t,weather_year) =l= Ramp_gas_mix * DRI_cap
;
eq_DRI_gas_blend3(t,weather_year)$[(ord(t)>1)$(not Sw_UC) $ Sw_flex_gas_blend $ Sw_DRI_blend_hour]..
    DRI_from_H2(t,weather_year) - DRI_from_H2(t-1,weather_year) =l= Ramp_gas_mix * DRI_cap
;
eq_DRI_gas_blend4(t,weather_year)$[(ord(t)=1)$(not Sw_UC) $ Sw_flex_gas_blend $ Sw_DRI_blend_hour]..
    DRI_from_H2(t,weather_year) - DRI_from_H2("t8760",weather_year) =l= Ramp_gas_mix * DRI_cap
;
eq_DRI_gas_blend5(t,weather_year)$[(ord(t)>1)$(not Sw_UC) $ Sw_flex_gas_blend $ Sw_DRI_blend_hour]..
    DRI_from_gas(t-1,weather_year) - DRI_from_gas(t,weather_year) =l= Ramp_gas_mix * DRI_cap
;
eq_DRI_gas_blend6(t,weather_year)$[(ord(t)=1)$(not Sw_UC) $ Sw_flex_gas_blend $ Sw_DRI_blend_hour]..
    DRI_from_gas("t8760",weather_year) - DRI_from_gas(t,weather_year) =l= Ramp_gas_mix * DRI_cap
;
eq_DRI_gas_blend7(t,weather_year)$[(ord(t)>1)$(not Sw_UC) $ Sw_flex_gas_blend $ Sw_DRI_blend_hour]..
    DRI_from_gas(t,weather_year) - DRI_from_gas(t-1,weather_year) =l= Ramp_gas_mix * DRI_cap
;
eq_DRI_gas_blend8(t,weather_year)$[(ord(t)=1)$(not Sw_UC) $ Sw_flex_gas_blend $ Sw_DRI_blend_hour]..
    DRI_from_gas(t,weather_year) - DRI_from_gas("t8760",weather_year) =l= Ramp_gas_mix * DRI_cap
;
eq_DRI_gas_blend9(group,t,weather_year)$[t_group(group,t) $ (not Sw_UC) $ Sw_flex_gas_blend $ (not Sw_DRI_blend_hour)]..
    DRI_from_gas(t,weather_year) =e= z(group,weather_year)
;
eq_DRI_gas_blend10(t,weather_year)$[(not Sw_UC) $ (not Sw_flex_gas_blend) $ (not Sw_DRI_blend_hour)]..
    DRI_from_gas(t,weather_year) =e= z4(weather_year)
;

* DRI from gas max share
eq_DRI_gas_max(t,weather_year)..
    DRI_from_gas(t,weather_year) =l= DRI_from_gas_max_ratio * (DRI_from_gas(t,weather_year) + DRI_from_H2(t,weather_year))
;

* DRI reheat penalty
eq_DRI_penalty(t,weather_year)..
    DRI_discharge(t,weather_year) * DRI_reheat_power_CONSUMPTION =e= DRI_reheat_power(t,weather_year)
;
eq_DRI_penalty1(t,weather_year)..
    DRI_penalty(t,weather_year) =e= DRI_discharge(t,weather_year) * 0.0000001
;

* Scrap ratio flexibility
eq_scrap_flexibility1(weather_year)$[Sw_flex_scrap]..
    sum(t, EAF_Scrap(t,weather_year)) =e= sum(t, Steel_gen(t,weather_year)) * scrap_ratio
;
eq_scrap_flexibility2(t,weather_year)$[not Sw_flex_scrap]..
    EAF_Scrap(t,weather_year) =e= Steel_gen(t,weather_year) * scrap_ratio
;

* DRI flexibility. if not flexible, we assume the maximum output is equal to the capacity     
eq_DRI_no_flexibility(t,weather_year)$[not Sw_flex_DRI]..
    DRI_gen(t,weather_year) =e= DRI_cap
;

* DRI flexibility. ramp constraints without UC        
eq_RampDown1_noUC(t,weather_year)$[(ord(t)>1)$(not Sw_UC) $ Sw_flex_DRI $ Sw_DRI_load_hour]..
    DRI_gen(t-1,weather_year) - DRI_gen(t,weather_year) =l= RampDownRate * DRI_cap
;
eq_RampDown2_noUC(t,weather_year)$[(ord(t)=1)$(not Sw_UC) $ Sw_flex_DRI $ Sw_DRI_load_hour]..
    DRI_gen("t8760",weather_year) - DRI_gen(t,weather_year) =l= RampDownRate * DRI_cap
;
eq_RampUp1_noUC(t,weather_year)$[(ord(t)>1)$(not Sw_UC) $ Sw_flex_DRI $ Sw_DRI_load_hour]..
    DRI_gen(t,weather_year) - DRI_gen(t-1,weather_year) =l= RampUpRate * DRI_cap
;
eq_RampUp2_noUC(t,weather_year)$[(ord(t)=1)$(not Sw_UC) $ Sw_flex_DRI $ Sw_DRI_load_hour]..
    DRI_gen(t,weather_year) - DRI_gen("t8760",weather_year) =l= RampUpRate * DRI_cap
;

eq_DRI_load(group2,t,weather_year)$[t_group2(group2,t) $ (not Sw_UC) $ Sw_flex_DRI $ (not Sw_DRI_load_hour)]..
    DRI_gen(t,weather_year) =e= z3(group2,weather_year)
;

* Steel market flexibility      
eq_steel_market_flexibility1(group1,weather_year)$[Sw_flex_steel_market]..
    sum(t_group1(group1,t), Steel_gen(t,weather_year)) =e= sum(t_group1(group1,t), Steel_DEMAND(t))
;
eq_steel_market_flexibility2(t,weather_year)$[not Sw_flex_steel_market]..
    Steel_gen(t,weather_year) =e= Steel_DEMAND(t)
;

eq_emission1(t,weather_year)..
    gas_emission(t,weather_year) =e= DRI_gas(t,weather_year) * Gas_unit_emission
;
eq_emission2(t,weather_year)..
    power_emission(t,weather_year) =e= grid(t,weather_year) * Gridpower_unit_emission
;
eq_emission3(t,weather_year)..
    emission(t,weather_year) =e= gas_emission(t,weather_year) + power_emission(t,weather_year)
;
eq_emission4(weather_year)..
    total_emission(weather_year) =e= sum(t, emission(t,weather_year))
;
eq_emission5(weather_year)$[Sw_adjusted_annual_emission]..
    total_emission(weather_year) =l= emission_cap + emission_relaxation(weather_year)
;
eq_emission6(weather_year)$[not Sw_adjusted_annual_emission]..
    total_emission(weather_year) =l= emission_cap
;

eq_Solar_cost..
    Solar_cost =e= GENC("Solar") * Power_cap("Solar")
;
eq_Wind_cost..
    Wind_cost =e= GENC("Wind") * Power_cap("Wind")
;
eq_Power_cost..
    Power_cost =e= Solar_cost + Wind_cost
;
eq_Electrolyzer_cost..
    Electrolyzer_cost =e= ele_cap * ELEC
;        
eq_Battery_cost..
    Battery_cost =e= bat_p_cap * BAT_PC + bat_e_cap * BAT_EC
;    
eq_Tank_cost..
    Tank_cost =e= tank_cap * TANKC
;
eq_DRI_furnace_cost..
    DRI_furnace_cost =e= DRI_cap * DRIC
;
eq_EAF_furnace_cost..
    EAF_furnace_cost =e= EAF_cap * EAFC
;     
eq_Iron_ore_cost(weather_year)..
    Iron_ore_cost(weather_year) =e= sum(t, DRI_ironore(t,weather_year) * Ironore_unit_cost)
;                  
eq_Scrap_cost(weather_year)..
    Scrap_cost(weather_year) =e= sum(t, EAF_Scrap(t,weather_year) * Scrap_unit_cost)
; 
eq_Gird_power_cost(weather_year)..
    Gird_power_cost(weather_year) =e= sum(t, grid(t,weather_year) * Gridpower_unit_cost)
;                  
eq_Gas_cost(weather_year)..
    Gas_cost(weather_year) =e= sum(t, DRI_gas(t,weather_year) * Gas_unit_cost)
; 

eq_Battery_penalty_cost(weather_year)..
    Battery_penalty_cost(weather_year) =e= sum(t, Battery_penalty(t,weather_year))
;
eq_DRI_penalty_cost(weather_year)..
    DRI_penalty_cost(weather_year) =e= sum(t, DRI_penalty(t,weather_year))
;
eq_IronLabor_cost..
    IronLabor_cost =e= sum((t,weather_year), DRI_gen(t,weather_year) * IronLabor_unit_cost) / card(weather_year)
;
eq_SteelLabor_cost..
    SteelLabor_cost =e= sum((t,weather_year), Steel_gen(t,weather_year) * SteelLabor_unit_cost) / card(weather_year)
;
eq_Other_material_cost..
    Other_material_cost =e= sum((t,weather_year), Steel_gen(t,weather_year) * Other_material_unit_cost) / card(weather_year)
;
eq_emission_cost(weather_year)$[Sw_adjusted_annual_emission]..
    Emission_cost(weather_year) =e= emission_relaxation(weather_year) * carbon_price / 1000000
;
eq_TC_variable$[not Sw_adjusted_annual_emission]..
    TVC =e= sum(weather_year, Iron_ore_cost(weather_year)
                   + Scrap_cost(weather_year)
                   + Gird_power_cost(weather_year)
                   + Gas_cost(weather_year)
                   + Battery_penalty_cost(weather_year)
                   + DRI_penalty_cost(weather_year)
              ) / card(weather_year)
;
eq_TC_annual(weather_year)$[not Sw_adjusted_annual_emission]..
    TC_annual(weather_year) =e= Power_cost
                            + Electrolyzer_cost
                            + Battery_cost
                            + Tank_cost
                            + DRI_furnace_cost
                            + EAF_furnace_cost
                            + Iron_ore_cost(weather_year)
                            + Scrap_cost(weather_year)
                            + Gird_power_cost(weather_year)
                            + Gas_cost(weather_year)
                            + IronLabor_cost
                            + SteelLabor_cost
                            + Other_material_cost
                            + Battery_penalty_cost(weather_year)
                            + DRI_penalty_cost(weather_year)
;
eq_TC$[not Sw_adjusted_annual_emission]..
    TC =e= Power_cost
       + Electrolyzer_cost
       + Battery_cost
       + Tank_cost
       + DRI_furnace_cost
       + EAF_furnace_cost
       + TVC
       + IronLabor_cost
       + SteelLabor_cost
       + Other_material_cost
;
* with emission relaxation and emission cost (but steel cost does not include emission cost)        
eq_TC_variable1$[Sw_adjusted_annual_emission]..
    TVC =e= sum(weather_year, Iron_ore_cost(weather_year)
                   + Scrap_cost(weather_year)
                   + Gird_power_cost(weather_year)
                   + Gas_cost(weather_year)
                   + Emission_cost(weather_year)
                   + Battery_penalty_cost(weather_year)
                   + DRI_penalty_cost(weather_year)
              ) / card(weather_year)
;
* this one is without emission cost
eq_TC_annual1(weather_year)$[Sw_adjusted_annual_emission]..
    TC_annual(weather_year) =e= Power_cost
                            + Electrolyzer_cost
                            + Battery_cost
                            + Tank_cost
                            + DRI_furnace_cost
                            + EAF_furnace_cost
                            + Iron_ore_cost(weather_year)
                            + Scrap_cost(weather_year)
                            + Gird_power_cost(weather_year)
                            + Gas_cost(weather_year)
                            + IronLabor_cost
                            + SteelLabor_cost
                            + Other_material_cost
                            + Battery_penalty_cost(weather_year)
                            + DRI_penalty_cost(weather_year)
;
eq_TC1$[Sw_adjusted_annual_emission]..
    TC =e= Power_cost
       + Electrolyzer_cost
       + Battery_cost
       + Tank_cost
       + DRI_furnace_cost
       + EAF_furnace_cost
       + TVC
       + IronLabor_cost
       + SteelLabor_cost
       + Other_material_cost
;
eq_switch_gas(t,weather_year)$[not Sw_gas_backup]..
    DRI_gas(t,weather_year) =e= 0
;
eq_switch_grid(t,weather_year)$[not Sw_grid_backup]..
    grid(t,weather_year) =e= 0
;
eq_gen_daysum(d,weather_year)..
    gen_daysum(d,weather_year) =e= sum((tech, dt(d,t)), gen(t,weather_year,tech))
;
eq_H2_gen_daysum(d,weather_year)..
    H2_gen_daysum(d,weather_year) =e= sum(dt(d,t), H2_gen(t,weather_year))
;
eq_DRI_gen_daysum(d,weather_year)..
    DRI_gen_daysum(d,weather_year) =e= sum(dt(d,t), DRI_gen(t,weather_year))
;
eq_DRI_from_H2_daysum(d,weather_year)..
    DRI_from_H2_daysum(d,weather_year) =e= sum(dt(d,t), DRI_from_H2(t,weather_year))
;
eq_DRI_from_gas_daysum(d,weather_year)..
    DRI_from_gas_daysum(d,weather_year) =e= sum(dt(d,t), DRI_from_gas(t,weather_year))
;        
eq_DRI_ironore_daysum(d,weather_year)..
    DRI_ironore_daysum(d,weather_year) =e= sum(dt(d,t), DRI_ironore(t,weather_year))
;
eq_EAF_DRI_daysum(d,weather_year)..
    EAF_DRI_daysum(d,weather_year) =e= sum(dt(d,t), EAF_DRI(t,weather_year))
;
eq_EAF_Scrap_daysum(d,weather_year)..
    EAF_Scrap_daysum(d,weather_year) =e= sum(dt(d,t), EAF_Scrap(t,weather_year))
;
eq_Steel_gen_daysum(d,weather_year)..
    Steel_gen_daysum(d,weather_year) =e= sum(dt(d,t), Steel_gen(t,weather_year))
;

* every group
eq_gen_groupsum(group,weather_year)..
    gen_groupsum(group,weather_year) =e= sum((tech, t_group(group,t)), gen(t,weather_year,tech))
;
eq_H2_gen_groupsum(group,weather_year)..
    H2_gen_groupsum(group,weather_year) =e= sum(t_group(group,t), H2_gen(t,weather_year))
;
eq_DRI_gen_groupsum(group,weather_year)..
    DRI_gen_groupsum(group,weather_year) =e= sum(t_group(group,t), DRI_gen(t,weather_year))
;
eq_DRI_from_H2_groupsum(group,weather_year)..
    DRI_from_H2_groupsum(group,weather_year) =e= sum(t_group(group,t), DRI_from_H2(t,weather_year))
;
eq_DRI_from_gas_groupsum(group,weather_year)..
    DRI_from_gas_groupsum(group,weather_year) =e= sum(t_group(group,t), DRI_from_gas(t,weather_year))
;        
eq_DRI_ironore_groupsum(group,weather_year)..
    DRI_ironore_groupsum(group,weather_year) =e= sum(t_group(group,t), DRI_ironore(t,weather_year))
;
eq_EAF_DRI_groupsum(group,weather_year)..
    EAF_DRI_groupsum(group,weather_year) =e= sum(t_group(group,t), EAF_DRI(t,weather_year))
;
eq_EAF_Scrap_groupsum(group,weather_year)..
    EAF_Scrap_groupsum(group,weather_year) =e= sum(t_group(group,t), EAF_Scrap(t,weather_year))
;
eq_Steel_gen_groupsum(group,weather_year)..
    Steel_gen_groupsum(group,weather_year) =e= sum(t_group(group,t), Steel_gen(t,weather_year))
;

set model_name / 
    Model_no_flexibility,
    Model_DRI_flexibility_noUC,
    Model_DRI_flexibility_UC,
    Model_scrap_flexibility,
    Model_steel_market_flexibility,
    Model_all_flexibility_noUC,
    Model_all_flexibility_UC
/;

* Power_cap.fx("solar")=0;

Model DRI_flexibility_noUC /
    eq_RampDown1_noUC,
    eq_RampDown2_noUC,
    eq_RampUp1_noUC,
    eq_RampUp2_noUC
/;

Model DRI_no_flexibility /
    eq_DRI_no_flexibility
/;

Model scrap_flexibility /
    eq_scrap_flexibility1
/;

Model scrap_no_flexibility /
    eq_scrap_flexibility2
/;

Model steel_market_flexibility /
    eq_steel_market_flexibility1
/;

Model steel_market_no_flexibility /
    eq_steel_market_flexibility2
/;

Model Model_no_flexibility / all -DRI_flexibility_noUC -scrap_flexibility -steel_market_flexibility /;

Model Model_DRI_flexibility_noUC / all -DRI_no_flexibility -scrap_flexibility -steel_market_flexibility /;

Model Model_DRI_flexibility_UC / all -DRI_no_flexibility -DRI_flexibility_noUC -scrap_flexibility -steel_market_flexibility /;

Model Model_steel_market_flexibility / all -DRI_flexibility_noUC -scrap_flexibility -steel_market_no_flexibility /;

Model Model_scrap_flexibility / all -DRI_flexibility_noUC -scrap_no_flexibility -steel_market_flexibility /;

Model Model_all_flexibility_noUC / all -DRI_no_flexibility -scrap_flexibility -steel_market_flexibility /;

Model Model_all_flexibility_UC / all -DRI_no_flexibility -DRI_flexibility_noUC -scrap_flexibility -steel_market_flexibility /;

Model Model_all / all /;


* write gdxxrw option File
$onEcho > gdxxrw_instructions.txt

    squeeze=n var=capacity_table.l rng=capacity!a1 rdim=1 cdim=0

    squeeze=n var=Power_balance.l rng=PowerBalance!a1 rdim=1 cdim=2                          
    squeeze=n var=H2_balance.l rng=H2_balance!a1 rdim=1 cdim=2                          
    squeeze=n var=DRI_balance.l rng=DRI_balance!a1 rdim=1 cdim=2                          
    squeeze=n var=Material.l rng=Material!a1 rdim=1 cdim=2                          

    squeeze=n var=Power_UtilizationHours.l rng=UtilizationHours!a1  rdim=1 cdim=1  
    squeeze=n var=ele_UtilizationHours.l rng=UtilizationHours!b5 rdim=0 cdim=1
    squeeze=n var=DRI_UtilizationHours.l rng=UtilizationHours!b7 rdim=0 cdim=1
    squeeze=n var=EAF_UtilizationHours.l rng=UtilizationHours!b9 rdim=0 cdim=1

    squeeze=n var=cost_structure.l rng=cost!b2 rdim=1 cdim=1

    squeeze=n var=total_Curt_rate.l rng=curt!a1  rdim=0 cdim=1

    squeeze=n var=emission_table.l rng=emission!d1 rdim=1 cdim=2


    squeeze=n var=LCOX_table.l rng=LCOX!d1 rdim=1 cdim=1


   

$offEcho


Option limrow = 0;
Option limcol = 0;
Model_all.solprint = 0;
Option threads = 0;

Gridpower_unit_cost = 0.00059 * grid_price_factor("k1");
Gridpower_unit_emission = 1.092 * grid_emission_factor("j1");

Gridpower_unit_cost = Gridpower_unit_cost_all_zone("BT");
Gas_unit_cost = Gas_unit_cost_all_zone("BT");
Gridpower_unit_emission = Gridpower_unit_emission_all_zone("BT");
Maxoutput_all_weather_year(t,tech,weather_year) = Maxoutput_all_region(t,"BT",tech,weather_year);

ELEC    = cost_table("electrolyzer","2035");
GENC("Solar") = cost_table("Solar","2035");
GENC("Wind")  = cost_table("Wind","2035");
BAT_PC  = cost_table("battery_power","2035");
BAT_EC  = cost_table("battery_energy","2035");

option clear = t_group;
option clear = t_group1;
option clear = t_group2;
option clear = t_group3;

* DRI gas blend
t_group(group,t) = ord(t) > (ord(group)-1) * (8760/60)
                and ord(t) <= ord(group) * (8760/60);
* steel demand
t_group1(group1,t) = ord(t) > (ord(group1)-1) * (8760/60)
                   and ord(t) <= ord(group1) * (8760/60);
* DRI load
t_group2(group2,t) = ord(t) > (ord(group2)-1) * (8760/60)
                   and ord(t) <= ord(group2) * (8760/60);
* grid
t_group3(group3,t) = ord(t) > (ord(group3)-1) * (8760/8760)
                   and ord(t) <= ord(group3) * (8760/8760);

solve Model_all using lp minimizing TC;
        
Power_UtilizationHours.l(tech,weather_year)$[Power_cap.l(tech)]
    = sum((t), GEN.l(t,weather_year,tech)) / Power_cap.l(tech);
Power_UtilizationHours.l(tech,weather_year)$[not Power_cap.l(tech)] = 0;

ELE_UtilizationHours.l(weather_year)$[ele_cap.l]
    = sum((t), ELE_power.l(t,weather_year)) / ele_cap.l;
ELE_UtilizationHours.l(weather_year)$[not ele_cap.l] = 0;

DRI_UtilizationHours.l(weather_year)$[DRI_cap.l]
    = sum((t), DRI_gen.l(t,weather_year)) / DRI_cap.l;
DRI_UtilizationHours.l(weather_year)$[not DRI_cap.l] = 0;

EAF_UtilizationHours.l(weather_year)$[EAF_cap.l]
    = sum((t), Steel_gen.l(t,weather_year)) / EAF_cap.l;
EAF_UtilizationHours.l(weather_year)$[not EAF_cap.l] = 0;

Steelcost.l = sum(weather_year, TC_annual.l(weather_year)) / card(weather_year)
            / sum(t, Steel_DEMAND(t)) * 1000000;

Curt.l(t,weather_year,tech)
    = Power_cap.l(tech) * Maxoutput_all_weather_year(t,tech,weather_year) - gen.l(t,weather_year,tech);
total_Curt_rate.l(weather_year)
    = sum((tech,t), Curt.l(t,weather_year,tech))
      / sum((tech,t), Power_cap.l(tech) * Maxoutput_all_weather_year(t,tech,weather_year));

Power_balance.l(t,weather_year, "Solar") = GEN.l(t,weather_year, "Solar");
Power_balance.l(t,weather_year, "Wind")  = GEN.l(t,weather_year, "Wind");
Power_balance.l(t,weather_year, "bat_discharge") = bat_discharge.l(t,weather_year);
Power_balance.l(t,weather_year, "bat_charge")    = bat_charge.l(t,weather_year);
Power_balance.l(t,weather_year, "grid")          = grid.l(t,weather_year);
Power_balance.l(t,weather_year, "ELE_power")      = ELE_power.l(t,weather_year);
Power_balance.l(t,weather_year, "DRI_power")      = DRI_power.l(t,weather_year);
Power_balance.l(t,weather_year, "EAF_power")      = EAF_power.l(t,weather_year);
Power_balance.l(t,weather_year, "DRI_reheat_power") = DRI_reheat_power.l(t,weather_year);
Power_balance.l(t,weather_year, "bat_sto")        = bat_sto.l(t,weather_year);

H2_balance.l(t,weather_year, "H2_gen")       = H2_gen.l(t,weather_year);
H2_balance.l(t,weather_year, "H2_discharge")   = H2_discharge.l(t,weather_year);
H2_balance.l(t,weather_year, "H2_charge")      = H2_charge.l(t,weather_year);
H2_balance.l(t,weather_year, "DRI_H2")         = DRI_H2.l(t,weather_year);
H2_balance.l(t,weather_year, "H2_sto")         = H2_sto.l(t,weather_year);

DRI_balance.l(t,weather_year, "DRI_gen")      = DRI_gen.l(t,weather_year);
DRI_balance.l(t,weather_year, "DRI_discharge")  = DRI_discharge.l(t,weather_year);
DRI_balance.l(t,weather_year, "DRI_charge")     = DRI_charge.l(t,weather_year);
DRI_balance.l(t,weather_year, "EAF_DRI")        = EAF_DRI.l(t,weather_year);
DRI_balance.l(t,weather_year, "DRI_from_H2")    = DRI_from_H2.l(t,weather_year);
DRI_balance.l(t,weather_year, "DRI_from_gas")   = DRI_from_gas.l(t,weather_year);
DRI_balance.l(t,weather_year, "DRI_sto")        = DRI_sto.l(t,weather_year);

Material.l(t,weather_year, "Steel_gen")   = Steel_gen.l(t,weather_year);
Material.l(t,weather_year, "DRI_ironore")   = DRI_ironore.l(t,weather_year);
Material.l(t,weather_year, "EAF_Scrap")     = EAF_Scrap.l(t,weather_year);

cost_structure.l("Wind_cost",weather_year)            = Wind_cost.l;
cost_structure.l("Solar_cost",weather_year)           = Solar_cost.l;
cost_structure.l("Battery_cost",weather_year)         = Battery_cost.l;
cost_structure.l("Electrolyzer_cost",weather_year)      = Electrolyzer_cost.l;
cost_structure.l("Tank_cost",weather_year)            = Tank_cost.l;
cost_structure.l("DRI_furnace_cost",weather_year)       = DRI_furnace_cost.l;
cost_structure.l("EAF_furnace_cost",weather_year)       = EAF_furnace_cost.l;
cost_structure.l("Iron_ore_cost",weather_year)        = Iron_ore_cost.l(weather_year);
cost_structure.l("Scrap_cost",weather_year)           = Scrap_cost.l(weather_year);
cost_structure.l("Gas_cost",weather_year)             = Gas_cost.l(weather_year);
cost_structure.l("Gird_power_cost",weather_year)      = Gird_power_cost.l(weather_year);
cost_structure.l("Other_material_unit_cost",weather_year) = Other_material_cost.l;
cost_structure.l("IronLabor_unit_cost",weather_year)  = IronLabor_cost.l;
cost_structure.l("SteelLabor_unit_cost",weather_year) = SteelLabor_cost.l;
cost_structure.l("Total_cost",weather_year)           = TC_annual.l(weather_year);

capacity_table.l("wind")          = Power_cap.l("wind");
capacity_table.l("solar")         = Power_cap.l("solar");
capacity_table.l("Battery_power") = bat_p_cap.l;
capacity_table.l("Battery_energy")= bat_e_cap.l;
capacity_table.l("Electrolyzer")  = ele_cap.l;
capacity_table.l("Tank")          = tank_cap.l;
capacity_table.l("DRI_furnace")   = DRI_cap.l;
capacity_table.l("EAF_furnace")   = EAF_cap.l;

emission_table.l(t,"gas_emission",weather_year)  = gas_emission.l(t,weather_year);
emission_table.l(t,"power_emission",weather_year)= power_emission.l(t,weather_year);
emission_table.l(t,"emission",weather_year)        = emission.l(t,weather_year);

LCOE.l(weather_year)
    = (Power_cost.l + Battery_cost.l)
      / sum(t, ELE_power.l(t,weather_year)
               + DRI_power.l(t,weather_year)
               + EAF_power.l(t,weather_year)
               + DRI_reheat_power.l(t,weather_year)
               - grid.l(t,weather_year)) * 1000000;

LCOE_wgrid.l(weather_year)
    = (LCOE.l(weather_year) / 1000000
       * sum(t, ELE_power.l(t,weather_year)
                  + DRI_power.l(t,weather_year)
                  + EAF_power.l(t,weather_year)
                  + DRI_reheat_power.l(t,weather_year)
                  - grid.l(t,weather_year))
       + Gridpower_unit_cost * sum(t, grid.l(t,weather_year)))
      / sum(t, ELE_power.l(t,weather_year)
                 + DRI_power.l(t,weather_year)
                 + EAF_power.l(t,weather_year)
                 + DRI_reheat_power.l(t,weather_year)) * 1000000;

LCOH_Wh.l(weather_year)
    = (Electrolyzer_cost.l + Tank_cost.l + LCOE_wgrid.l(weather_year) / 1000000 * sum(t, ELE_power.l(t,weather_year)))
      / sum(t, DRI_H2.l(t,weather_year)) * 1000000;
LCOH_kg.l(weather_year)
    = LCOH_Wh.l(weather_year) * 0.03333;

LCOD.l(weather_year)
    = (DRI_furnace_cost.l + Iron_ore_cost.l(weather_year)
       + Gas_cost.l(weather_year) + IronLabor_cost.l
       + LCOE_wgrid.l(weather_year) / 1000000 * sum(t, DRI_power.l(t,weather_year))
       + LCOH_Wh.l(weather_year) / 1000000 * sum(t, DRI_H2.l(t,weather_year)))
      / sum(t, DRI_gen.l(t,weather_year)) * 1000000;

LCOS.l(weather_year) = TC_annual.l(weather_year) / 10;

LCOX_table.l("LCOE", weather_year)       = LCOE.l(weather_year);
LCOX_table.l("LCOE_wgrid", weather_year)   = LCOE_wgrid.l(weather_year);
LCOX_table.l("LCOH_Wh", weather_year)      = LCOH_Wh.l(weather_year);
LCOX_table.l("LCOH_kg", weather_year)      = LCOH_kg.l(weather_year);
LCOX_table.l("LCOD", weather_year)         = LCOD.l(weather_year);
LCOX_table.l("LCOS", weather_year)         = LCOS.l(weather_year);

daysum_table.l(d,weather_year,"gen")          = gen_daysum.l(d,weather_year);
daysum_table.l(d,weather_year,"H2_gen")         = H2_gen_daysum.l(d,weather_year);
daysum_table.l(d,weather_year,"DRI_gen")        = DRI_gen_daysum.l(d,weather_year);
daysum_table.l(d,weather_year,"DRI_from_H2")      = DRI_from_H2_daysum.l(d,weather_year);
daysum_table.l(d,weather_year,"DRI_from_gas")     = DRI_from_gas_daysum.l(d,weather_year);
daysum_table.l(d,weather_year,"DRI_ironore")      = DRI_ironore_daysum.l(d,weather_year);
daysum_table.l(d,weather_year,"EAF_DRI")          = EAF_DRI_daysum.l(d,weather_year);
daysum_table.l(d,weather_year,"EAF_Scrap")        = EAF_Scrap_daysum.l(d,weather_year);
daysum_table.l(d,weather_year,"Steel_gen")        = Steel_gen_daysum.l(d,weather_year);



execute_unload "Model_all.gdx"
put_utility 'exec' / 'gdxxrw.exe Model_all.gdx o=steel_output.xlsm @gdxxrw_instructions.txt';

