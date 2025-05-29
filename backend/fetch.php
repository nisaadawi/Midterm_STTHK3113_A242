<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include_once("dbconfig.php"); // This should include your database connection

$device_id = isset($_GET['device_id']) ? $_GET['device_id'] : '';

if (!$device_id) {
    echo json_encode(["status" => "error", "message" => "Device ID is required"]);
    exit;
}

$sql = "SELECT temperature, humidity, relay_status, timestamp 
        FROM tbl_dht11 
        WHERE device_id = ? 
        ORDER BY timestamp DESC 
        LIMIT 20";

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $device_id);
$stmt->execute();
$result = $stmt->get_result();

$data = [];
while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

if (!empty($data)) {
    echo json_encode([
        "status" => "success",
        "data" => $data
    ]);
} else {
    echo json_encode([
        "status" => "success",
        "data" => []
    ]);
}

$conn->close();
?>
