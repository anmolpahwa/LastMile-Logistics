# MMH-UAV

## planning horizon

	years                   :   10
	days                    :   330
	discount rate           :   0.03
	discounted working days :   330 * (1 - 1.03 ^ -10) / 0.03 = 2814.97

## regional distribution facility

	location                :   (50,0)

#### class-8 diesel truck fleet

	capacity                :   1800 packages
	speed                   :   20 mph
	fixed cost              :   $120,000 / 2814.97 = $42.629
	operational cost        :   ($35/hr / 20 mph  + $0.190/mile + $3.860/gal * 0.125gal/mile + $0.589/mile) = $3.012
	pcu                     :   2.0 passenger car units
	CO2                     :   1592 g/mile
	CO                      :   0.81 g/mile
	NOx                     :   5.55 g/mile
	PM                      :   0.09 g/mile

## primary distribution facility

	location                :   (1,0) | (25,0) | (49,0)
	capacity                :   2000
	throughput share        :   [0,1]
	working hours           :   8AM - 8PM
	fixed cost              :   356.37 * (sqrt(x ^ 2 + y ^ 2) ^ (-0.231)) * capacity * 5 / 2814.97
	operational cost        :   2 * distance to the regional distribution facility * $3.012/mile  / 1800 packages
	
#### diesel van fleet + unmanned aerial vehicles

	capacity                :   360 packages
	range                   :   350 miles | 6 miles
	speed                   :   20 mph | 15 mph
	refueling time          :   (350 miles * 0.067gal/mile) / (35 gal/min) / 60 = 0.011 hrs
	facility time           :   0.300 / 60 = 0.005 hrs
	parking time            :   2.500 / 60 = 0.042 hrs
	work load (hours)       :   9 hrs
	work load (routes)      :   6 routes
	operational cost (dist) :   ($0.250/mile + $3.860/gal * 0.067 gal/mile + $0.236/mile) = $0.745/mile *
	operational cost (time) :   $35/hr
	fixed cost              :   $45,000 + $12,000 / 2814.97 = $20.249
	pcu                     :   1.5 passenger car units
	CO2                     :   549.0 g/mile
	CO                      :   0.500 g/mile
	NOx                     :   2.420 g/mile
	PM                      :   0.021 g/mile

	* UAV operational cost to be added post-optimization
	operational cost (dist) : ($0.265/mile + $0.12/kWh * 0.118kWh/mile) = $0.279/mile

## customer stop node

	number of stops         :   estimated based on the multinomial logit model developed in Jaller and Pahwa (2020)
	number of customers     :   3 / customer stop
	location                :   randomly located within each census tract
	demand                  :   1 unit / customer
	service time            :   1.000 / 60 = 0.050 hrs / customer
	time-window             :   8AM - 8PM

	Jaller, M., & Pahwa, A. (2020). Evaluating the environmental impacts of online shopping: A behavioral and 
	   transportation approach. Transportation Research Part D: Transport and Environment, 80, 102223.