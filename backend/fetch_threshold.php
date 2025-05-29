<?php
header("Content-Type: application/json");

// Include the database configuration file
include_once 'dbconfig.php';

// Check if the connection from dbconfig.php is available
if (!$conn) {
    echo json_encode(["status" => "error", "message" => "Database connection not available"]);
    exit();
}

// Fetch the latest threshold values
// This query orders by ID descending and limits to 1 to get the most recent entry
$sql = "SELECT temp_treshold, hum_treshold FROM treshold_controller ORDER BY id DESC LIMIT 1";
$result = $conn->query($sql);

if ($result) {
    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        echo json_encode(["status" => "success", "data" => $row]);
    } else {
        echo json_encode(["status" => "error", "message" => "No thresholds found"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Error fetching thresholds: " . $conn->error]);
}

$conn->close();
?>