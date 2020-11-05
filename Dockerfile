 #Use a minimal base image with OpenJDK installed
 FROM openjdk:8-jre-alpine3.7

 #Install packages
RUN apk update && \    
    apk add ca-certificates wget python3 py-pip && \
    pip3 install awscli && \    
    update-ca-certificates

 #Set variables
 ENV JMETER_HOME=/usr/share/apache-jmeter \    
    JMETER_VERSION=3.3 \    
    WEB_SOCKET_SAMPLER_VERSION=1.2 \    
    TEST_SCRIPT_FILE=./jmeter/test.jmx \    
    TEST_LOG_FILE=./jmeter/test.log \    
    TEST_RESULTS_FILE=./jmeter/test-result.xml \    
    USE_CACHED_SSL_CONTEXT=false \    
    NUMBER_OF_THREADS=700 \    
    RAMP_UP_TIME=10 \    
    CERTIFICATES_FILE=./jmeter/certificates.csv \    
    KEYSTORE_FILE=./jmeter/keystore.jks \    
    KEYSTORE_PASSWORD=secret \
    HTML_REPORT_FILE=./jmeter/html/index.html \    
    HOST=83y9aapwd4.execute-api.sa-east-1.amazonaws.com \    
    RESOURCEPATH=/teste/123456/id-exposicao-python-dynamodb-dax \
    PORT=443 \    
    OPEN_CONNECTION_WAIT_TIME=500 \    
    OPEN_CONNECTION_TIMEOUT=2000 \    
    OPEN_CONNECTION_READ_TIMEOUT=600 \    
    NUMBER_OF_MESSAGES=1 \    
    DATA_TO_SEND=cafebabecafebabe \    
    BEFORE_SEND_DATA_WAIT_TIME=500 \    
    SEND_DATA_WAIT_TIME=1000 \    
    SEND_DATA_READ_TIMEOUT=600 \    
    CLOSE_CONNECTION_WAIT_TIME=500 \    
    CLOSE_CONNECTION_READ_TIMEOUT=600 \
    PATH="~/.local/bin:$PATH" \    
    JVM_ARGS="-Xms4096m -Xmx8196m -XX:NewSize=1024m -XX:MaxNewSize=2048m -Duser.timezone=UTC"

 #Install Apache JMeter
 RUN wget http://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz && \    
    tar zxvf apache-jmeter-${JMETER_VERSION}.tgz && \    
    rm -f apache-jmeter-${JMETER_VERSION}.tgz && \    
    mv apache-jmeter-${JMETER_VERSION} ${JMETER_HOME}

 #Install WebSocket samplers
 RUN wget https://bitbucket.org/pjtr/jmeter-websocket-samplers/downloads/JMeterWebSocketSamplers-${WEB_SOCKET_SAMPLER_VERSION}.jar && \    
    mv JMeterWebSocketSamplers-${WEB_SOCKET_SAMPLER_VERSION}.jar ${JMETER_HOME}/lib/ext

 #Copy test plan
 COPY ./jmeter/test.jmx ${TEST_SCRIPT_FILE}

 #Copy keystore and table
 #COPY certs.jks ${KEYSTORE_FILE}
 #COPY certs.csv ${CERTIFICATES_FILE}

 #Expose port
 EXPOSE 443

 #The main command, where several things happen:
 #- Empty the log and result files63#
 #- Start the JMeter script64#
 #- Echo the log and result files' contents
 CMD echo -n > $TEST_LOG_FILE && \    
    echo -n > $TEST_RESULTS_FILE && \    
    export PATH=~/.local/bin:$PATH && \    
    $JMETER_HOME/bin/jmeter -n \    
    -t=$TEST_SCRIPT_FILE \    
    -j=$TEST_LOG_FILE \    
    -l=$TEST_RESULTS_FILE \
    -g=./jmeter/test.csv \
    -o=./jmeter/html \ 
    -Djavax.net.ssl.keyStore=$KEYSTORE_FILE \    
    -Djavax.net.ssl.keyStorePassword=$KEYSTORE_PASSWORD \    
    -Jhttps.use.cached.ssl.context=$USE_CACHED_SSL_CONTEXT \    
    -Jjmeter.save.saveservice.output_format=xml \    
    -Jjmeter.save.saveservice.response_data=true \    
    -Jjmeter.save.saveservice.samplerData=true \
    -Jjmeter.reportgenerator.report_title=Dashboard \
    -Jjmeter.reportgenerator.date_format=yyyyMMddHHmmss \
    -Jjmeter.reportgenerator.overall_granularity=60000 \
    -Jjmeter.reportgenerator.graph.responseTimeDistribution.property.set_granularity=100 \
    -Jjmeter.reportgenerator.apdex_satisfied_threshold=500 \
    -Jjmeter.reportgenerator.apdex_tolerated_threshold=1500 \
    -Jjmeter.reportgenerator.exporter.html.show_controllers_only=false \
    -Jjmeter.reportgenerator.exported_transactions_pattern=[a-zA-Z0-9_\\-{}\\$\\.]*[-_][0-9]* \
    -Jjmeter.reportgenerator.graph.custom_mm_hit.title=Data Masker API \
    -Jjmeter.reportgenerator.graph.custom_mm_hit.property.set_Y_Axis=Response Time \
    -Jjmeter.reportgenerator.graph.custom_mm_hit.property.set_X_Axis=Over Time \
    -Jjmeter.reportgenerator.graph.custom_mm_hit.property.set_granularity=${jmeter.reportgenerator.overall_granularity} \
    -Jjmeter.reportgenerator.graph.custom_mm_hit.property.setContentMessage=Message for graph point label \    
    -JnumberOfThreads=$NUMBER_OF_THREADS \    
    -JrampUpTime=$RAMP_UP_TIME \    
    -JcertFile=$CERTIFICATES_FILE \    
    -Jhost=$HOST \    
    -JresourcePath=$RESOURCEPATH \ 
    -Jport=$PORT \    
    -JopenConnectionWaitTime=$OPEN_CONNECTION_WAIT_TIME \    
    -JopenConnectionConnectTimeout=$OPEN_CONNECTION_TIMEOUT \    
    -JopenConnectionReadTimeout=$OPEN_CONNECTION_READ_TIMEOUT \    
    -JnumberOfMessages=$NUMBER_OF_MESSAGES \    
    -JdataToSend=$DATA_TO_SEND \    
    -JbeforeSendDataWaitTime=$BEFORE_SEND_DATA_WAIT_TIME \    
    -JsendDataWaitTime=$SEND_DATA_WAIT_TIME \    
    -JsendDataReadTimeout=$SEND_DATA_READ_TIMEOUT \    
    -JcloseConnectionWaitTime=$CLOSE_CONNECTION_WAIT_TIME \    
    -JcloseConnectionReadTimeout=$CLOSE_CONNECTION_READ_TIMEOUT && \
    aws s3 cp $TEST_LOG_FILE s3://jmeter-image1/html/ && \
    aws s3 cp $TEST_RESULTS_FILE s3://jmeter-image1/html/ && \
    aws s3 cp $HTML_REPORT_FILE s3://jmeter-image1/html/ && \    
    echo -e "\n\n===== TEST LOGS =====\n\n" && \    
    cat $TEST_LOG_FILE && \    
    echo -e "\n\n===== TEST RESULTS =====\n\n" && \    
    cat $TEST_RESULTS_FILE
