local dbconfig = {
	player = {
		dbServiceName = ".playerdb%d",
		instAmount = 8,
		conf = {
			host="127.0.0.1",
			port=3306,
			database="paradise_gs",
			user="root",
			password="1",
			max_packet_size = 1024 * 1024
		}
	},

	service = {
		dbServiceName = ".servicedb%d",
		instAmount = 1,
		conf = {
			host="127.0.0.1",
			port=3306,
			database="paradise_gs",
			user="root",
			password="1",
			max_packet_size = 1024 * 1024
		}
	},

	operationanalyze = {
		dbServiceName = ".oadb%d",
		instAmount = 8,
		conf = {
			host="127.0.0.1",
			port=3306,
			database="paradise_oa",
			user="root",
			password="1",
			max_packet_size = 1024 * 1024
		}
	}
}

return dbconfig
