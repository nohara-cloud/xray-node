package pmpanel

import "encoding/json"

// NodeInfoResponse is the response of node
type NodeInfoResponse struct {
	Port       uint32  `json:"port"`
	Method     string  `json:"method"`
	SpeedLimit float64 `json:"speed_limit"`
	// Shadowsocks 2022 require server key
	ServerKey string `json:"server_key"`
	// TrafficRate     float64 `json:"trafficRate"`
	// RawServerString string  `json:"outServer"`
	// AlterId         uint16  `json:"alterId"`
	// Network         string  `json:"network"`
	// Security        string  `json:"security"`
	// Host            string  `json:"host"`
	// Path string `json:"path"`
	// Grpc            bool    `json:"grpc"`
	// Sni             string  `json:"sni"`
}

// UserResponse is the response of user
type UserResponse struct {
	ID          string  `json:"id"`
	Passwd      string  `json:"token"`
	SpeedLimit  float64 `json:"speed_limit"`
	DeviceLimit int     `json:"device_limit"`
}

// Response is the common response
type Response struct {
	Ret  uint            `json:"ret"`
	Data json.RawMessage `json:"data"`
}

// PostData is the data structure of post data
type PostData struct {
	Type    string      `json:"type"`
	NodeId  string      `json:"nodeId"`
	Users   interface{} `json:"users"`
	Onlines interface{} `json:"onlines"`
}

// SystemLoad is the data structure of systemload
type SystemLoad struct {
	Uptime string `json:"uptime"`
	Load   string `json:"load"`
}

// OnlineUser is the data structure of online user
type OnlineUser struct {
	UID string `json:"userId"`
	IP  string `json:"ip"`
}

// UserTraffic is the data structure of traffic
type UserTraffic struct {
	UID      string `json:"userId"`
	Upload   int64  `json:"upload"`
	Download int64  `json:"download"`
	Ip       string `json:"ip"`
}

type RuleItem struct {
	ID      int    `json:"id"`
	Content string `json:"regex"`
}

type IllegalItem struct {
	ID  int    `json:"list_id"`
	UID string `json:"user_id"`
}
