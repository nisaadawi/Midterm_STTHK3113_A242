<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

include_once("dbconfig.php");


try {

    // Get device_id from request
    $device_id = isset($_GET['device_id']) ? $_GET['device_id'] : null;

    if ($device_id === null) {
        throw new Exception('Device ID is required');
    }

    // Change LIMIT 1 to LIMIT 10 (or any number you want)
        $stmt = $conn->prepare("
        SELECT temperature, humidity, relay_status, timestamp 
        FROM tbl_dht11 
        WHERE device_id = ? 
        ORDER BY timestamp DESC 
        LIMIT 30
    ");
    
    $stmt->bindParam(1, $device_id);
    $stmt->execute();
    
    $results = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if ($results) {
        $data = [];
        foreach ($results as $row) {
            $data[] = [
                'temperature' => (float)$row['temperature'],
                'humidity' => (float)$row['humidity'],
                'relay_status' => $row['relay_status'],
                'timestamp' => $row['timestamp']
            ];
        }
        $response = [
            'status' => 'success',
            'data' => $data
        ];
    } else {
        $response = [
            'status' => 'error',
            'message' => 'No data found for this device'
        ];
    }

    echo json_encode($response);

} catch (PDOException $e) {
    // Handle database errors
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Database error: ' . $e->getMessage()
    ]);
} catch (Exception $e) {
    // Handle other errors
    http_response_code(400);
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}
?> 