package pmpanel

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

// OnlineUser is the data structure of online user
type OnlineUser struct {
	UID string `json:"user_id"`
	IP  string `json:"ip"`
}

type OnlineUserPostData struct {
	Online []OnlineUser `json:"online"`
}

// UserTraffic is the data structure of traffic
type UserTraffic struct {
	UID      string `json:"user_id"`
	Upload   int64  `json:"upload"`
	Download int64  `json:"download"`
}

type TrafficPostData struct {
	Traffic []UserTraffic `json:"traffic"`
}

// NodeStatus is the data structure of node status
type NodeStatus struct {
	CPU    float64 `json:"cpu"`
	Mem    float64 `json:"mem"`
	Disk   float64 `json:"disk"`
	Uptime uint64  `json:"uptime"`
}

type RuleItem struct {
	ID      int    `json:"id"`
	Content string `json:"regex"`
}

type IllegalItem struct {
	ID  int    `json:"list_id"`
	UID string `json:"user_id"`
}
