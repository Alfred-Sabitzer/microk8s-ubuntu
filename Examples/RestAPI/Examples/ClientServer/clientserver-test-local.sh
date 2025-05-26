#!/bin/bash
############################################################################################
# Test Running Service
############################################################################################
#shopt -o -s errexit	#—Terminates  the shell	script if a	command	returns	an error code.
shopt -o -s xtrace	#—Displays each	command	before it’s	executed.
shopt -o -s nounset	#-No Variables without definition
shopt -s dotglob # Use shopt -u dotglob to exclude hidden directories
IFS="
"
go run clientserver

podip="localhost:8080"

curl http://${podip}
#"[\n  {\n    \"title\": \"Spring Quiet\"\n  },\n  {\n    \"title\": \"The Meadows In Spring\"\n  },\n  {\n    \"title\": \"The Notice that is called the Spring\"\n  },\n  {\n    \"title\": \"The inundation of the Spring\"\n  },\n  {\n    \"title\": \"A little Madness in the Spring\"\n  },\n  {\n    \"title\": \"I have a Bird in spring\"\n  },\n  {\n    \"title\": \"A Pang is more conspicuous in Spring\"\n  },\n  {\n    \"title\": \"Before you thought of Spring\"\n  },\n  {\n    \"title\": \"I cannot meet the Spring unmoved --\"\n  },\n  {\n    \"title\": \"Spring comes on the World --\"\n  },\n  {\n    \"title\": \"A Light exists in Spring\"\n  },\n  {\n    \"title\": \"Spring is the Period\"\n  },\n  {\n    \"title\": \"A spring poem from bion\"\n  },\n  {\n    \"title\": \"Spring\"\n  },\n  {\n    \"title\": \"Spring \u0026 Fall: To A Young Child\"\n  },\n  {\n    \"title\": \"THE ARSENAL AT SPRINGFIELD\"\n  },\n  {\n    \"title\": \"Song To A Fair Young Lady Going Out Of Town In The Spring\"\n  },\n  {\n    \"title\": \"To a Blackbird and His Mate Who Died in the Spring\"\n  },\n  {\n    \"title\": \"The Progress of Spring\"\n  },\n  {\n    \"title\": \"Spring\"\n  },\n  {\n    \"title\": \"Nay, Lord, not thus! white lilies in the spring,\"\n  },\n  {\n    \"title\": \"From Spring Days To Winter (For Music)\"\n  },\n  {\n    \"title\": \"Spring's Messengers\"\n  },\n  {\n    \"title\": \"538. Song—Now Spring has clad the grove in green\"\n  },\n  {\n    \"title\": \"101. Song—Composed in Spring\"\n  },\n  {\n    \"title\": \"HOW SPRINGS CAME FIRST\"\n  },\n  {\n    \"title\": \"FAREWELL FROST, OR WELCOME SPRING\"\n  },\n  {\n    \"title\": \"Flower God, God Of The Spring\"\n  },\n  {\n    \"title\": \"Spring Song\"\n  },\n  {\n    \"title\": \"Spring Carol\"\n  },\n  {\n    \"title\": \"In The Green And Gallant Spring\"\n  },\n  {\n    \"title\": \"My Springs\"\n  },\n  {\n    \"title\": \"Spring Greeting\"\n  },\n  {\n    \"title\": \"Ode On The Spring\"\n  },\n  {\n    \"title\": \"In spring and summer winds may blow\"\n  },\n  {\n    \"title\": \"These, I, Singing in Spring.\"\n  },\n  {\n    \"title\": \"Spring Offensive\"\n  },\n  {\n    \"title\": \"In a Spring Grove\"\n  },\n  {\n    \"title\": \"On a Forenoon of Spring\"\n  },\n  {\n    \"title\": \"Spring in Town\"\n  },\n  {\n    \"title\": \"Spring\"\n  },\n  {\n    \"title\": \"Spring and Winter ii\"\n  },\n  {\n    \"title\": \"Spring and Winter i\"\n  },\n  {\n    \"title\": \"Spring\"\n  },\n  {\n    \"title\": \"Lines Written In Early Spring\"\n  },\n  {\n    \"title\": \"Sonnet 98: From you have I been absent in the spring\"\n  },\n  {\n    \"title\": \"The Sleep of Spring\"\n  },\n  {\n    \"title\": \"Early Spring\"\n  },\n  {\n    \"title\": \"To a Lady, on Being Asked My Reason for Quitting England in the Spring\"\n  },\n  {\n    \"title\": \"Spring\"\n  },\n  {\n    \"title\": \"Spring.\"\n  }\n]"

curl -X POST -H 'content-type: application/json' --data '{"id":123,"title":"Test"}' http://${podip}
# Status 200 OK

curl -X PUT -H 'content-type: application/json' --data '{"id":123,"title":"Test"}' http://${podip}
# Status 200 OK
