// Package comprehensive provides an exhaustive demonstration of all Go language
// constructs and syntax patterns. This file is used as a test fixture for
// scope.nvim, a Neovim plugin that uses Treesitter to parse Go files for
// hierarchical scope-based symbol navigation.
//
// DO NOT attempt to compile or run this file as a real program. Some sections
// contain intentionally unusual patterns to exercise Treesitter edge cases.
package comprehensive

import (
	"bufio"
	"bytes"
	"context"
	"crypto/rand"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"math"
	"math/big"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"reflect"
	"regexp"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"syscall"
	"testing"
	"time"
	"unicode/utf8"
	"unsafe"
)

// ---------------------------------------------------------------------------
// Section 1: Package-level constants
// ---------------------------------------------------------------------------

// Single constant
const Pi = 3.14159265358979323846

// Typed constant
const MaxRetries int = 5

// Untyped constant
const DefaultTimeout = 30 * time.Second

// Constant block with iota
const (
	StatusPending Status = iota
	StatusActive
	StatusSuspended
	StatusClosed
	StatusArchived
)

// Iota with bit shifting
const (
	PermRead Permission = 1 << iota
	PermWrite
	PermExecute
	PermAdmin
	PermSuper = PermRead | PermWrite | PermExecute | PermAdmin
)

// String constants
const (
	AppName    = "scope-test"
	AppVersion = "1.0.0"
	UserAgent  = AppName + "/" + AppVersion

	DefaultHost = "localhost"
	DefaultPort = 8080

	PathSeparator = string(os.PathSeparator)

	MultiLineString = `This is a raw string literal
that spans multiple lines
and preserves whitespace and "quotes" and 'apostrophes'
and backslashes \ without escaping`

	EscapedString = "This has\ttabs\nand newlines\nand \"escaped quotes\""
)

// Numeric constants
const (
	HexValue    = 0xFF
	OctalValue  = 0o77
	BinaryValue = 0b11111111
	FloatValue  = 1.23e10
	ImagValue   = 2.5i
	RuneValue   = 'A'
	BigNumber   = 1_000_000_000
	HexFloat    = 0x1.fp10
)

// ---------------------------------------------------------------------------
// Section 2: Package-level variables
// ---------------------------------------------------------------------------

// Single variable declarations
var (
	globalCounter int
	globalMutex   sync.Mutex
	globalOnce    sync.Once
)

// Typed variable with initialization
var defaultLogger *log.Logger = log.New(os.Stderr, "[scope-test] ", log.LstdFlags)

// Variable block
var (
	errNotFound     = errors.New("not found")
	errUnauthorized = errors.New("unauthorized")
	errForbidden    = errors.New("forbidden")
	errTimeout      = errors.New("operation timed out")
	errCancelled    = errors.New("operation cancelled")
)

// Variables with complex initializations
var (
	defaultConfig = Config{
		Host:       DefaultHost,
		Port:       DefaultPort,
		Timeout:    DefaultTimeout,
		MaxRetries: MaxRetries,
	}

	supportedFormats = map[string]bool{
		"json": true,
		"xml":  true,
		"yaml": true,
		"toml": true,
	}

	defaultHeaders = http.Header{
		"Content-Type": []string{"application/json"},
		"User-Agent":   []string{UserAgent},
	}

	regexpEmail    = regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
	regexpURL      = regexp.MustCompile(`^https?://[^\s/$.?#].[^\s]*$`)
	regexpUsername = regexp.MustCompile(`^[a-zA-Z][a-zA-Z0-9_]{2,31}$`)
)

// ---------------------------------------------------------------------------
// Section 3: Type declarations — basic named types
// ---------------------------------------------------------------------------

// Type aliases
type (
	Status           int
	Permission       int
	UserID           string
	Score            float64
	Callback         func(ctx context.Context, data []byte) error
	Middleware       func(http.Handler) http.Handler
	StringSlice      []string
	ByteChannel      chan []byte
	ReadOnlyChannel  <-chan int
	WriteOnlyChannel chan<- string
	ErrorMap         map[string][]error
)

// ---------------------------------------------------------------------------
// Section 4: Struct types — simple to complex
// ---------------------------------------------------------------------------

// Simple struct
type Point struct {
	X float64
	Y float64
}

// Struct with tags
type Config struct {
	Host       string        `json:"host" yaml:"host" env:"APP_HOST"`
	Port       int           `json:"port" yaml:"port" env:"APP_PORT"`
	Timeout    time.Duration `json:"timeout" yaml:"timeout"`
	MaxRetries int           `json:"max_retries" yaml:"max_retries"`
	Debug      bool          `json:"debug,omitempty" yaml:"debug"`
}

// Struct with embedded types
type Server struct {
	Config
	*log.Logger
	http.Handler

	name      string
	started   time.Time
	mu        sync.RWMutex
	listeners []net.Listener
	quit      chan struct{}
	wg        sync.WaitGroup
}

// Nested struct definitions
type Database struct {
	Primary struct {
		Host     string
		Port     int
		Name     string
		User     string
		Password string
		SSLMode  string
		Pool     struct {
			MaxOpen     int
			MaxIdle     int
			MaxLifetime time.Duration
		}
	}
	Replicas []struct {
		Host   string
		Port   int
		Weight int
	}
	Options map[string]interface{}
}

// Struct with function fields
type EventHandler struct {
	OnConnect    func(conn net.Conn) error
	OnDisconnect func(conn net.Conn, err error)
	OnMessage    func(conn net.Conn, msg []byte) ([]byte, error)
	OnError      func(err error)
	middleware   []func([]byte) ([]byte, error)
}

// Generic struct
type Result[T any] struct {
	Value T
	Error error
	Meta  map[string]string
}

// Generic struct with multiple type parameters
type Pair[K comparable, V any] struct {
	Key   K
	Value V
}

// Generic struct with constraints
type OrderedMap[K comparable, V any] struct {
	keys   []K
	values map[K]V
	mu     sync.RWMutex
}

// Deeply nested struct for complex configuration
type ApplicationConfig struct {
	Server struct {
		HTTP struct {
			Addr         string
			ReadTimeout  time.Duration
			WriteTimeout time.Duration
			IdleTimeout  time.Duration
			TLS          struct {
				Enabled  bool
				CertFile string
				KeyFile  string
			}
		}
		GRPC struct {
			Addr           string
			MaxRecvMsgSize int
			MaxSendMsgSize int
			Interceptors   []string
			KeepAlive      struct {
				Time    time.Duration
				Timeout time.Duration
			}
		}
	}
	Database struct {
		Driver          string
		DSN             string
		MaxOpenConns    int
		MaxIdleConns    int
		ConnMaxLifetime time.Duration
		Migrations      struct {
			Dir       string
			AutoRun   bool
			AllowDown bool
		}
	}
	Cache struct {
		Type  string
		TTL   time.Duration
		Redis struct {
			Addr     string
			Password string
			DB       int
		}
	}
	Logging struct {
		Level  string
		Format string
		Output string
	}
}

// Struct with all primitive field types
type AllTypes struct {
	BoolField       bool
	IntField        int
	Int8Field       int8
	Int16Field      int16
	Int32Field      int32
	Int64Field      int64
	UintField       uint
	Uint8Field      uint8
	Uint16Field     uint16
	Uint32Field     uint32
	Uint64Field     uint64
	UintptrField    uintptr
	Float32Field    float32
	Float64Field    float64
	Complex64Field  complex64
	Complex128Field complex128
	StringField     string
	ByteField       byte
	RuneField       rune
	ErrorField      error
	AnyField        any
	InterfaceField  interface{}
	UnsafeField     unsafe.Pointer
}

// ---------------------------------------------------------------------------
// Section 5: Interface types
// ---------------------------------------------------------------------------

// Empty interface
type Any interface{}

// Single method interface
type Stringer interface {
	String() string
}

// Multiple method interface
type Repository interface {
	Get(ctx context.Context, id string) (interface{}, error)
	List(ctx context.Context, filter Filter) ([]interface{}, error)
	Create(ctx context.Context, entity interface{}) error
	Update(ctx context.Context, id string, entity interface{}) error
	Delete(ctx context.Context, id string) error
	Count(ctx context.Context, filter Filter) (int64, error)
}

// Interface with embedded interfaces
type ReadWriteCloser interface {
	io.Reader
	io.Writer
	io.Closer
}

// Interface with type constraints (generics)
type Number interface {
	~int | ~int8 | ~int16 | ~int32 | ~int64 |
		~uint | ~uint8 | ~uint16 | ~uint32 | ~uint64 |
		~float32 | ~float64
}

// Interface with comparable constraint
type Ordered interface {
	Number | ~string
}

// Complex generic interface
type Cache[K comparable, V any] interface {
	Get(key K) (V, bool)
	Set(key K, value V, ttl time.Duration)
	Delete(key K)
	Clear()
	Len() int
	Keys() []K
}

// Interface for the plugin's own domain
type ScopeProvider interface {
	BuildTree(bufnr int) (*ScopeTree, error)
	SupportsLanguage(lang string) bool
	Name() string
}

// Interface with unexported methods (cannot be implemented outside package)
type internal interface {
	sealed()
	process(data []byte) error
}

// ---------------------------------------------------------------------------
// Section 6: Type assertions and type switches used later
// ---------------------------------------------------------------------------

type Filter struct {
	Field    string
	Operator string
	Value    interface{}
	And      []Filter
	Or       []Filter
}

type ScopeTree struct {
	Root   *ScopeNode
	Source string
	BufNr  int
	Lang   string
}

type ScopeNode struct {
	Name     string
	Kind     string
	Range    Range
	Children []*ScopeNode
	Parent   *ScopeNode
	IsScope  bool
	IsError  bool
}

type Range struct {
	StartRow int
	StartCol int
	EndRow   int
	EndCol   int
}

// ---------------------------------------------------------------------------
// Section 7: Init functions
// ---------------------------------------------------------------------------

func init() {
	globalCounter = 0
	defaultLogger.SetPrefix("[scope-test-init] ")
}

func init() {
	if os.Getenv("DEBUG") == "1" {
		defaultLogger.SetFlags(log.LstdFlags | log.Lshortfile)
	}
}

// ---------------------------------------------------------------------------
// Section 8: Simple functions
// ---------------------------------------------------------------------------

// Function with no parameters and no return
func doNothing() {
}

// Function with parameters and no return
func logMessage(level string, msg string) {
	defaultLogger.Printf("[%s] %s", level, msg)
}

// Function with single return value
func add(a, b int) int {
	return a + b
}

// Function with named return values
func divide(a, b float64) (result float64, err error) {
	if b == 0 {
		err = errors.New("division by zero")
		return
	}
	result = a / b
	return
}

// Function with multiple return values
func parseHostPort(addr string) (string, int, error) {
	parts := strings.SplitN(addr, ":", 2)
	if len(parts) != 2 {
		return "", 0, fmt.Errorf("invalid address: %s", addr)
	}
	port, err := strconv.Atoi(parts[1])
	if err != nil {
		return "", 0, fmt.Errorf("invalid port: %w", err)
	}
	return parts[0], port, nil
}

// Variadic function
func sum(nums ...int) int {
	total := 0
	for _, n := range nums {
		total += n
	}
	return total
}

// Function taking a function parameter
func apply(values []int, fn func(int) int) []int {
	result := make([]int, len(values))
	for i, v := range values {
		result[i] = fn(v)
	}
	return result
}

// Function returning a function (closure factory)
func multiplier(factor int) func(int) int {
	return func(x int) int {
		return x * factor
	}
}

// Function with complex signature
func processRequests(
	ctx context.Context,
	requests <-chan *http.Request,
	responses chan<- *http.Response,
	errCh chan<- error,
	opts ...func(*processorConfig),
) error {
	cfg := &processorConfig{}
	for _, opt := range opts {
		opt(cfg)
	}

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case req, ok := <-requests:
			if !ok {
				return nil
			}
			resp, err := processRequest(ctx, req, cfg)
			if err != nil {
				errCh <- err
				continue
			}
			responses <- resp
		}
	}
}

type processorConfig struct {
	maxRetries int
	timeout    time.Duration
	rateLimit  float64
}

func processRequest(ctx context.Context, req *http.Request, cfg *processorConfig) (*http.Response, error) {
	return nil, nil
}

// ---------------------------------------------------------------------------
// Section 9: Generic functions
// ---------------------------------------------------------------------------

// Simple generic function
func Map[T any, U any](slice []T, fn func(T) U) []U {
	result := make([]U, len(slice))
	for i, v := range slice {
		result[i] = fn(v)
	}
	return result
}

// Generic function with comparable constraint
func Contains[T comparable](slice []T, item T) bool {
	for _, v := range slice {
		if v == item {
			return true
		}
	}
	return false
}

// Generic function with custom constraint
func Min[T Number](a, b T) T {
	if a < b {
		return a
	}
	return b
}

// Generic function with multiple constraints
func GroupBy[T any, K comparable](items []T, keyFn func(T) K) map[K][]T {
	groups := make(map[K][]T)
	for _, item := range items {
		key := keyFn(item)
		groups[key] = append(groups[key], item)
	}
	return groups
}

// Generic function returning a generic struct
func NewResult[T any](value T, err error) Result[T] {
	return Result[T]{
		Value: value,
		Error: err,
		Meta:  make(map[string]string),
	}
}

// Generic function with pointer constraint
func Zero[T any]() T {
	var zero T
	return zero
}

// ---------------------------------------------------------------------------
// Section 10: Methods on structs
// ---------------------------------------------------------------------------

// Value receiver methods
func (p Point) Distance(other Point) float64 {
	dx := p.X - other.X
	dy := p.Y - other.Y
	return math.Sqrt(dx*dx + dy*dy)
}

func (p Point) String() string {
	return fmt.Sprintf("(%f, %f)", p.X, p.Y)
}

func (p Point) IsOrigin() bool {
	return p.X == 0 && p.Y == 0
}

// Pointer receiver methods
func (p *Point) Translate(dx, dy float64) {
	p.X += dx
	p.Y += dy
}

func (p *Point) Scale(factor float64) {
	p.X *= factor
	p.Y *= factor
}

func (p *Point) Reset() {
	p.X = 0
	p.Y = 0
}

// Methods on Config
func (c Config) Validate() error {
	var errs []error
	if c.Host == "" {
		errs = append(errs, errors.New("host is required"))
	}
	if c.Port <= 0 || c.Port > 65535 {
		errs = append(errs, fmt.Errorf("invalid port: %d", c.Port))
	}
	if c.Timeout <= 0 {
		errs = append(errs, errors.New("timeout must be positive"))
	}
	if c.MaxRetries < 0 {
		errs = append(errs, errors.New("max_retries must be non-negative"))
	}
	if len(errs) > 0 {
		return fmt.Errorf("validation failed: %v", errs)
	}
	return nil
}

func (c Config) Address() string {
	return fmt.Sprintf("%s:%d", c.Host, c.Port)
}

func (c *Config) ApplyDefaults() {
	if c.Host == "" {
		c.Host = DefaultHost
	}
	if c.Port == 0 {
		c.Port = DefaultPort
	}
	if c.Timeout == 0 {
		c.Timeout = DefaultTimeout
	}
	if c.MaxRetries == 0 {
		c.MaxRetries = MaxRetries
	}
}

// Methods with complex bodies
func (s *Server) Start(ctx context.Context) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if err := s.Config.Validate(); err != nil {
		return fmt.Errorf("invalid config: %w", err)
	}

	s.started = time.Now()
	s.quit = make(chan struct{})

	listener, err := net.Listen("tcp", s.Config.Address())
	if err != nil {
		return fmt.Errorf("failed to listen: %w", err)
	}
	s.listeners = append(s.listeners, listener)

	s.wg.Add(1)
	go func() {
		defer s.wg.Done()
		for {
			conn, err := listener.Accept()
			if err != nil {
				select {
				case <-s.quit:
					return
				default:
					s.Logger.Printf("accept error: %v", err)
					continue
				}
			}
			s.wg.Add(1)
			go func(c net.Conn) {
				defer s.wg.Done()
				defer c.Close()
				s.handleConnection(ctx, c)
			}(conn)
		}
	}()

	s.Logger.Printf("server started on %s", s.Config.Address())
	return nil
}

func (s *Server) Stop(ctx context.Context) error {
	s.mu.Lock()
	close(s.quit)
	s.mu.Unlock()

	for _, l := range s.listeners {
		if err := l.Close(); err != nil {
			s.Logger.Printf("error closing listener: %v", err)
		}
	}

	done := make(chan struct{})
	go func() {
		s.wg.Wait()
		close(done)
	}()

	select {
	case <-done:
		s.Logger.Println("server stopped gracefully")
		return nil
	case <-ctx.Done():
		return fmt.Errorf("shutdown timed out: %w", ctx.Err())
	}
}

func (s *Server) handleConnection(ctx context.Context, conn net.Conn) {
	scanner := bufio.NewScanner(conn)
	for scanner.Scan() {
		line := scanner.Text()
		if line == "quit" {
			break
		}

		response, err := s.processLine(ctx, line)
		if err != nil {
			fmt.Fprintf(conn, "ERROR: %v\n", err)
			continue
		}
		fmt.Fprintf(conn, "%s\n", response)
	}
	if err := scanner.Err(); err != nil {
		s.Logger.Printf("scanner error: %v", err)
	}
}

func (s *Server) processLine(ctx context.Context, line string) (string, error) {
	parts := strings.Fields(line)
	if len(parts) == 0 {
		return "", errors.New("empty command")
	}

	command := parts[0]
	args := parts[1:]

	switch command {
	case "ping":
		return "pong", nil
	case "echo":
		return strings.Join(args, " "), nil
	case "time":
		return time.Now().Format(time.RFC3339), nil
	case "uptime":
		uptime := time.Since(s.started)
		return uptime.String(), nil
	case "count":
		s.mu.RLock()
		count := globalCounter
		s.mu.RUnlock()
		return strconv.Itoa(count), nil
	default:
		return "", fmt.Errorf("unknown command: %s", command)
	}
}

// Methods on generic types
func (r Result[T]) IsError() bool {
	return r.Error != nil
}

func (r Result[T]) Unwrap() (T, error) {
	return r.Value, r.Error
}

func (r *Result[T]) SetMeta(key, value string) {
	if r.Meta == nil {
		r.Meta = make(map[string]string)
	}
	r.Meta[key] = value
}

func (om *OrderedMap[K, V]) Set(key K, value V) {
	om.mu.Lock()
	defer om.mu.Unlock()

	if om.values == nil {
		om.values = make(map[K]V)
	}

	if _, exists := om.values[key]; !exists {
		om.keys = append(om.keys, key)
	}
	om.values[key] = value
}

func (om *OrderedMap[K, V]) Get(key K) (V, bool) {
	om.mu.RLock()
	defer om.mu.RUnlock()

	v, ok := om.values[key]
	return v, ok
}

func (om *OrderedMap[K, V]) Keys() []K {
	om.mu.RLock()
	defer om.mu.RUnlock()

	keys := make([]K, len(om.keys))
	copy(keys, om.keys)
	return keys
}

func (om *OrderedMap[K, V]) Delete(key K) {
	om.mu.Lock()
	defer om.mu.Unlock()

	if _, exists := om.values[key]; !exists {
		return
	}

	delete(om.values, key)

	for i, k := range om.keys {
		if k == key {
			om.keys = append(om.keys[:i], om.keys[i+1:]...)
			break
		}
	}
}

func (om *OrderedMap[K, V]) Range(fn func(key K, value V) bool) {
	om.mu.RLock()
	defer om.mu.RUnlock()

	for _, key := range om.keys {
		if !fn(key, om.values[key]) {
			break
		}
	}
}

// Methods on named types
func (s StringSlice) Contains(item string) bool {
	for _, v := range s {
		if v == item {
			return true
		}
	}
	return false
}

func (s StringSlice) Filter(fn func(string) bool) StringSlice {
	var result StringSlice
	for _, v := range s {
		if fn(v) {
			result = append(result, v)
		}
	}
	return result
}

func (s StringSlice) Join(sep string) string {
	return strings.Join([]string(s), sep)
}

// Methods implementing sort.Interface
type ByName []ScopeNode

func (a ByName) Len() int           { return len(a) }
func (a ByName) Swap(i, j int)      { a[i], a[j] = a[j], a[i] }
func (a ByName) Less(i, j int) bool { return a[i].Name < a[j].Name }

// ---------------------------------------------------------------------------
// Section 11: Control flow — if/else
// ---------------------------------------------------------------------------

func demonstrateIfElse(x int) string {
	// Simple if
	if x > 0 {
		logMessage("info", "positive")
	}

	// If-else
	if x%2 == 0 {
		logMessage("info", "even")
	} else {
		logMessage("info", "odd")
	}

	// If-else if-else chain
	if x < 0 {
		return "negative"
	} else if x == 0 {
		return "zero"
	} else if x < 10 {
		return "small"
	} else if x < 100 {
		return "medium"
	} else if x < 1000 {
		return "large"
	} else {
		return "huge"
	}
}

func demonstrateIfWithInit() {
	// If with initialization statement
	if v := math.Sqrt(100); v > 5 {
		fmt.Println("sqrt > 5:", v)
	}

	// If with error check (extremely common Go pattern)
	if err := doSomething(); err != nil {
		log.Printf("error: %v", err)
	}

	// Nested if with init
	if f, err := os.Open("test.txt"); err == nil {
		defer f.Close()
		if info, err := f.Stat(); err == nil {
			if info.Size() > 1024 {
				fmt.Println("large file")
			}
		}
	}

	// Multi-condition if
	if a, b := 10, 20; a < b && b < 30 || a == 10 {
		fmt.Println("complex condition met")
	}
}

func doSomething() error { return nil }

// ---------------------------------------------------------------------------
// Section 12: Control flow — for loops
// ---------------------------------------------------------------------------

func demonstrateForLoops() {
	// Classic three-component for
	for i := 0; i < 10; i++ {
		fmt.Println(i)
	}

	// While-style for
	count := 0
	for count < 100 {
		count++
	}

	// Infinite loop
	for {
		if count > 200 {
			break
		}
		count++
	}

	// Range over slice
	items := []string{"a", "b", "c", "d"}
	for i, v := range items {
		fmt.Printf("%d: %s\n", i, v)
	}

	// Range over slice (index only)
	for i := range items {
		fmt.Println(i)
	}

	// Range over slice (value only)
	for _, v := range items {
		fmt.Println(v)
	}

	// Range over map
	m := map[string]int{"a": 1, "b": 2, "c": 3}
	for k, v := range m {
		fmt.Printf("%s=%d\n", k, v)
	}

	// Range over string (runes)
	for i, r := range "Hello, 世界" {
		fmt.Printf("byte %d: rune %c (U+%04X)\n", i, r, r)
	}

	// Range over channel
	ch := make(chan int, 5)
	go func() {
		for i := 0; i < 5; i++ {
			ch <- i
		}
		close(ch)
	}()
	for v := range ch {
		fmt.Println(v)
	}

	// Range over integer (Go 1.22+)
	for i := range 10 {
		fmt.Println(i)
	}

	// Nested for loops
	for i := 0; i < 3; i++ {
		for j := 0; j < 3; j++ {
			for k := 0; k < 3; k++ {
				if i+j+k > 5 {
					break
				}
				fmt.Printf("%d,%d,%d\n", i, j, k)
			}
		}
	}

	// For with continue
	for i := 0; i < 20; i++ {
		if i%3 == 0 {
			continue
		}
		fmt.Println(i)
	}

	// For with labeled break
outer:
	for i := 0; i < 10; i++ {
		for j := 0; j < 10; j++ {
			if i*j > 25 {
				break outer
			}
		}
	}

	// For with labeled continue
loop:
	for i := 0; i < 5; i++ {
		for j := 0; j < 5; j++ {
			if j == 3 {
				continue loop
			}
			fmt.Println(i, j)
		}
	}
}

// ---------------------------------------------------------------------------
// Section 13: Control flow — switch statements
// ---------------------------------------------------------------------------

func demonstrateSwitch(x int) {
	// Basic switch
	switch x {
	case 1:
		fmt.Println("one")
	case 2:
		fmt.Println("two")
	case 3:
		fmt.Println("three")
	default:
		fmt.Println("other")
	}

	// Switch with multiple values per case
	switch x {
	case 1, 3, 5, 7, 9:
		fmt.Println("odd")
	case 2, 4, 6, 8, 10:
		fmt.Println("even")
	}

	// Switch with initialization
	switch v := x * 2; {
	case v < 10:
		fmt.Println("small")
	case v < 100:
		fmt.Println("medium")
	default:
		fmt.Println("large")
	}

	// Tagless switch (acts like if-else)
	switch {
	case x < 0:
		fmt.Println("negative")
	case x == 0:
		fmt.Println("zero")
	case x > 0 && x < 100:
		fmt.Println("positive, small")
	default:
		fmt.Println("positive, large")
	}

	// Switch with fallthrough
	switch x {
	case 1:
		fmt.Println("one")
		fallthrough
	case 2:
		fmt.Println("one or two")
		fallthrough
	case 3:
		fmt.Println("one, two, or three")
	}

	// Switch with break
	switch x {
	case 1:
		if x > 0 {
			break
		}
		fmt.Println("unreachable")
	}
}

// Type switch
func demonstrateTypeSwitch(val interface{}) string {
	switch v := val.(type) {
	case nil:
		return "nil"
	case bool:
		return fmt.Sprintf("bool: %v", v)
	case int:
		return fmt.Sprintf("int: %d", v)
	case int64:
		return fmt.Sprintf("int64: %d", v)
	case float64:
		return fmt.Sprintf("float64: %f", v)
	case string:
		return fmt.Sprintf("string: %q", v)
	case []byte:
		return fmt.Sprintf("bytes: %x", v)
	case []int:
		return fmt.Sprintf("int slice: %v (len %d)", v, len(v))
	case map[string]interface{}:
		return fmt.Sprintf("map: %d keys", len(v))
	case error:
		return fmt.Sprintf("error: %v", v)
	case fmt.Stringer:
		return fmt.Sprintf("stringer: %s", v.String())
	case io.Reader:
		return "reader"
	default:
		return fmt.Sprintf("unknown: %T", v)
	}
}

// Type switch with multiple types per case
func isNumeric(val interface{}) bool {
	switch val.(type) {
	case int, int8, int16, int32, int64,
		uint, uint8, uint16, uint32, uint64,
		float32, float64, complex64, complex128:
		return true
	default:
		return false
	}
}

// ---------------------------------------------------------------------------
// Section 14: Control flow — select statements
// ---------------------------------------------------------------------------

func demonstrateSelect(ctx context.Context) {
	ch1 := make(chan string)
	ch2 := make(chan int)
	timer := time.NewTimer(5 * time.Second)
	ticker := time.NewTicker(100 * time.Millisecond)
	defer timer.Stop()
	defer ticker.Stop()

	// Basic select
	select {
	case msg := <-ch1:
		fmt.Println("received string:", msg)
	case num := <-ch2:
		fmt.Println("received int:", num)
	case <-timer.C:
		fmt.Println("timeout")
	}

	// Select with default (non-blocking)
	select {
	case msg := <-ch1:
		fmt.Println("got:", msg)
	default:
		fmt.Println("no message available")
	}

	// Select in a loop (common pattern)
	for {
		select {
		case <-ctx.Done():
			fmt.Println("context cancelled:", ctx.Err())
			return
		case <-ticker.C:
			fmt.Println("tick")
		case msg, ok := <-ch1:
			if !ok {
				fmt.Println("channel closed")
				return
			}
			fmt.Println("message:", msg)
		}
	}
}

// Fan-out pattern
func fanOut(ctx context.Context, input <-chan int, workers int) []<-chan int {
	outputs := make([]<-chan int, workers)
	for i := 0; i < workers; i++ {
		out := make(chan int)
		outputs[i] = out
		go func(ch chan<- int) {
			defer close(ch)
			for {
				select {
				case <-ctx.Done():
					return
				case v, ok := <-input:
					if !ok {
						return
					}
					ch <- v * 2
				}
			}
		}(out)
	}
	return outputs
}

// Fan-in pattern
func fanIn(ctx context.Context, channels ...<-chan int) <-chan int {
	out := make(chan int)
	var wg sync.WaitGroup

	for _, ch := range channels {
		wg.Add(1)
		go func(c <-chan int) {
			defer wg.Done()
			for {
				select {
				case <-ctx.Done():
					return
				case v, ok := <-c:
					if !ok {
						return
					}
					select {
					case out <- v:
					case <-ctx.Done():
						return
					}
				}
			}
		}(ch)
	}

	go func() {
		wg.Wait()
		close(out)
	}()

	return out
}

// ---------------------------------------------------------------------------
// Section 15: Defer, panic, and recover
// ---------------------------------------------------------------------------

func demonstrateDefer() {
	// Simple defer
	fmt.Println("start")
	defer fmt.Println("deferred: last")
	defer fmt.Println("deferred: middle")
	defer fmt.Println("deferred: first")
	fmt.Println("end")

	// Defer with closure capturing loop variable
	for i := 0; i < 5; i++ {
		defer func(n int) {
			fmt.Println("deferred loop:", n)
		}(i)
	}

	// Defer for resource cleanup
	f, err := os.CreateTemp("", "test")
	if err != nil {
		return
	}
	defer func() {
		f.Close()
		os.Remove(f.Name())
	}()

	// Defer with named return value modification
	result, err := deferredReturn()
	fmt.Println(result, err)
}

func deferredReturn() (result string, err error) {
	defer func() {
		if err != nil {
			result = "fallback"
		}
	}()

	// Simulate work that might fail
	if time.Now().Unix()%2 == 0 {
		return "", errors.New("even second")
	}
	return "success", nil
}

func demonstratePanicRecover() {
	// Recover from panic
	defer func() {
		if r := recover(); r != nil {
			fmt.Println("recovered from panic:", r)
			// Print stack trace
			buf := make([]byte, 4096)
			n := runtime.Stack(buf, false)
			fmt.Println("stack:", string(buf[:n]))
		}
	}()

	// This will panic
	panic("something went wrong")
}

func safeDivide(a, b int) (result int, err error) {
	defer func() {
		if r := recover(); r != nil {
			err = fmt.Errorf("panic in divide: %v", r)
		}
	}()
	return a / b, nil
}

// Panic with typed value
func mustParseJSON(data []byte) map[string]interface{} {
	var result map[string]interface{}
	if err := json.Unmarshal(data, &result); err != nil {
		panic(fmt.Errorf("mustParseJSON: %w", err))
	}
	return result
}

// ---------------------------------------------------------------------------
// Section 16: Goroutines and channels
// ---------------------------------------------------------------------------

func demonstrateGoroutines() {
	// Simple goroutine
	go func() {
		fmt.Println("hello from goroutine")
	}()

	// Goroutine with WaitGroup
	var wg sync.WaitGroup
	for i := 0; i < 10; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			time.Sleep(time.Duration(id) * time.Millisecond)
			fmt.Printf("worker %d done\n", id)
		}(i)
	}
	wg.Wait()

	// Buffered channel
	buffered := make(chan int, 10)
	for i := 0; i < 10; i++ {
		buffered <- i
	}
	close(buffered)

	// Unbuffered channel for synchronization
	done := make(chan struct{})
	go func() {
		// Do work
		time.Sleep(100 * time.Millisecond)
		close(done)
	}()
	<-done

	// Channel direction in function types
	producer := func(out chan<- int) {
		for i := 0; i < 5; i++ {
			out <- i
		}
		close(out)
	}

	consumer := func(in <-chan int) {
		for v := range in {
			fmt.Println(v)
		}
	}

	ch := make(chan int)
	go producer(ch)
	consumer(ch)
}

// Pipeline pattern
func generateNumbers(ctx context.Context, limit int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for i := 0; i < limit; i++ {
			select {
			case out <- i:
			case <-ctx.Done():
				return
			}
		}
	}()
	return out
}

func squareNumbers(ctx context.Context, in <-chan int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for v := range in {
			select {
			case out <- v * v:
			case <-ctx.Done():
				return
			}
		}
	}()
	return out
}

func filterEven(ctx context.Context, in <-chan int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for v := range in {
			if v%2 == 0 {
				select {
				case out <- v:
				case <-ctx.Done():
					return
				}
			}
		}
	}()
	return out
}

// Semaphore pattern using buffered channel
type Semaphore struct {
	ch chan struct{}
}

func NewSemaphore(max int) *Semaphore {
	return &Semaphore{ch: make(chan struct{}, max)}
}

func (s *Semaphore) Acquire() {
	s.ch <- struct{}{}
}

func (s *Semaphore) Release() {
	<-s.ch
}

// Worker pool
func workerPool(ctx context.Context, jobs <-chan func() error, numWorkers int) <-chan error {
	errs := make(chan error, numWorkers)
	var wg sync.WaitGroup

	for i := 0; i < numWorkers; i++ {
		wg.Add(1)
		go func(workerID int) {
			defer wg.Done()
			for {
				select {
				case <-ctx.Done():
					return
				case job, ok := <-jobs:
					if !ok {
						return
					}
					if err := job(); err != nil {
						select {
						case errs <- fmt.Errorf("worker %d: %w", workerID, err):
						default:
							// Error channel full, log and continue
							log.Printf("worker %d: dropped error: %v", workerID, err)
						}
					}
				}
			}
		}(i)
	}

	go func() {
		wg.Wait()
		close(errs)
	}()

	return errs
}

// ---------------------------------------------------------------------------
// Section 17: Synchronization primitives
// ---------------------------------------------------------------------------

// Mutex-protected resource
type SafeCounter struct {
	mu    sync.Mutex
	count map[string]int
}

func NewSafeCounter() *SafeCounter {
	return &SafeCounter{
		count: make(map[string]int),
	}
}

func (c *SafeCounter) Increment(key string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.count[key]++
}

func (c *SafeCounter) Get(key string) int {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.count[key]
}

// RWMutex for read-heavy workloads
type SafeMap[K comparable, V any] struct {
	mu   sync.RWMutex
	data map[K]V
}

func NewSafeMap[K comparable, V any]() *SafeMap[K, V] {
	return &SafeMap[K, V]{
		data: make(map[K]V),
	}
}

func (m *SafeMap[K, V]) Load(key K) (V, bool) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	v, ok := m.data[key]
	return v, ok
}

func (m *SafeMap[K, V]) Store(key K, value V) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.data[key] = value
}

func (m *SafeMap[K, V]) Delete(key K) {
	m.mu.Lock()
	defer m.mu.Unlock()
	delete(m.data, key)
}

func (m *SafeMap[K, V]) Range(fn func(K, V) bool) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	for k, v := range m.data {
		if !fn(k, v) {
			break
		}
	}
}

// sync.Once usage
type singleton struct {
	instance *Database
	once     sync.Once
}

func (s *singleton) GetInstance() *Database {
	s.once.Do(func() {
		s.instance = &Database{}
	})
	return s.instance
}

// sync.Pool usage
var bufferPool = sync.Pool{
	New: func() interface{} {
		return new(bytes.Buffer)
	},
}

func processWithPool(data []byte) string {
	buf := bufferPool.Get().(*bytes.Buffer)
	defer func() {
		buf.Reset()
		bufferPool.Put(buf)
	}()

	buf.Write(data)
	return buf.String()
}

// sync.Map
var globalCache sync.Map

func cacheOperations() {
	globalCache.Store("key1", "value1")
	globalCache.Store("key2", 42)

	if v, ok := globalCache.Load("key1"); ok {
		fmt.Println("cached:", v)
	}

	globalCache.LoadOrStore("key3", "default")
	globalCache.Delete("key2")

	globalCache.Range(func(key, value interface{}) bool {
		fmt.Printf("%v: %v\n", key, value)
		return true
	})
}

// sync.Cond
type EventBus struct {
	mu     sync.Mutex
	cond   *sync.Cond
	events []string
	closed bool
}

func NewEventBus() *EventBus {
	eb := &EventBus{}
	eb.cond = sync.NewCond(&eb.mu)
	return eb
}

func (eb *EventBus) Publish(event string) {
	eb.mu.Lock()
	defer eb.mu.Unlock()
	eb.events = append(eb.events, event)
	eb.cond.Broadcast()
}

func (eb *EventBus) Subscribe(ctx context.Context) <-chan string {
	ch := make(chan string, 10)
	go func() {
		defer close(ch)
		lastIndex := 0
		for {
			eb.mu.Lock()
			for lastIndex >= len(eb.events) && !eb.closed {
				eb.cond.Wait()
			}
			if eb.closed && lastIndex >= len(eb.events) {
				eb.mu.Unlock()
				return
			}
			newEvents := eb.events[lastIndex:]
			lastIndex = len(eb.events)
			eb.mu.Unlock()

			for _, event := range newEvents {
				select {
				case ch <- event:
				case <-ctx.Done():
					return
				}
			}
		}
	}()
	return ch
}

// Atomic operations
type AtomicCounter struct {
	value atomic.Int64
}

func (c *AtomicCounter) Increment() int64 {
	return c.value.Add(1)
}

func (c *AtomicCounter) Decrement() int64 {
	return c.value.Add(-1)
}

func (c *AtomicCounter) Get() int64 {
	return c.value.Load()
}

func (c *AtomicCounter) Reset() {
	c.value.Store(0)
}

// ---------------------------------------------------------------------------
// Section 18: Error handling patterns
// ---------------------------------------------------------------------------

// Custom error types
type AppError struct {
	Code    int
	Message string
	Cause   error
	Stack   string
}

func (e *AppError) Error() string {
	if e.Cause != nil {
		return fmt.Sprintf("[%d] %s: %v", e.Code, e.Message, e.Cause)
	}
	return fmt.Sprintf("[%d] %s", e.Code, e.Message)
}

func (e *AppError) Unwrap() error {
	return e.Cause
}

func (e *AppError) Is(target error) bool {
	t, ok := target.(*AppError)
	if !ok {
		return false
	}
	return e.Code == t.Code
}

// Sentinel errors
var (
	ErrNotFound     = &AppError{Code: 404, Message: "not found"}
	ErrUnauthorized = &AppError{Code: 401, Message: "unauthorized"}
	ErrForbidden    = &AppError{Code: 403, Message: "forbidden"}
	ErrConflict     = &AppError{Code: 409, Message: "conflict"}
	ErrInternal     = &AppError{Code: 500, Message: "internal error"}
	ErrBadRequest   = &AppError{Code: 400, Message: "bad request"}
	ErrRateLimit    = &AppError{Code: 429, Message: "rate limit exceeded"}
)

// Error wrapping
func fetchUser(ctx context.Context, id string) (*User, error) {
	user, err := queryDatabase(ctx, id)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, fmt.Errorf("fetchUser(%s): %w", id, ErrNotFound)
		}
		return nil, fmt.Errorf("fetchUser(%s): database error: %w", id, err)
	}
	return user, nil
}

// Multi-error collection
type MultiError struct {
	errors []error
}

func (me *MultiError) Add(err error) {
	if err != nil {
		me.errors = append(me.errors, err)
	}
}

func (me *MultiError) Error() string {
	if len(me.errors) == 0 {
		return ""
	}
	var sb strings.Builder
	for i, err := range me.errors {
		if i > 0 {
			sb.WriteString("; ")
		}
		sb.WriteString(err.Error())
	}
	return sb.String()
}

func (me *MultiError) HasErrors() bool {
	return len(me.errors) > 0
}

func (me *MultiError) Unwrap() []error {
	return me.errors
}

// Error checking patterns
func demonstrateErrorHandling() {
	// errors.Is
	err := fetchUser(context.Background(), "123")
	if errors.Is(err, ErrNotFound) {
		fmt.Println("user not found")
	}

	// errors.As
	var appErr *AppError
	if errors.As(err, &appErr) {
		fmt.Printf("app error code: %d\n", appErr.Code)
	}

	// errors.Join (Go 1.20+)
	errs := errors.Join(
		errors.New("first"),
		errors.New("second"),
		nil,
		errors.New("third"),
	)
	fmt.Println(errs)
}

type User struct {
	ID    string
	Name  string
	Email string
}

func queryDatabase(ctx context.Context, id string) (*User, error) {
	return nil, sql.ErrNoRows
}

// ---------------------------------------------------------------------------
// Section 19: Closures and anonymous functions
// ---------------------------------------------------------------------------

func demonstrateClosures() {
	// Closure capturing loop variable
	var funcs []func()
	for i := 0; i < 5; i++ {
		i := i // shadow to capture
		funcs = append(funcs, func() {
			fmt.Println(i)
		})
	}

	// Immediately invoked function expression (IIFE)
	result := func(x, y int) int {
		return x + y
	}(3, 4)
	fmt.Println(result)

	// Closure as accumulator
	counter := func() func() int {
		n := 0
		return func() int {
			n++
			return n
		}
	}()
	fmt.Println(counter(), counter(), counter())

	// Closure with multiple returns
	makeAdder := func(base int) (add func(int) int, reset func()) {
		current := base
		add = func(n int) int {
			current += n
			return current
		}
		reset = func() {
			current = base
		}
		return
	}
	addFive, resetFive := makeAdder(5)
	fmt.Println(addFive(3))
	resetFive()

	// Recursive closure (must declare variable first)
	var fibonacci func(n int) int
	fibonacci = func(n int) int {
		if n <= 1 {
			return n
		}
		return fibonacci(n-1) + fibonacci(n-2)
	}
	fmt.Println(fibonacci(10))

	// Closure modifying outer state
	total := 0
	increment := func(amount int) {
		total += amount
	}
	increment(5)
	increment(10)
	fmt.Println("total:", total)

	// Closure as method value
	p := Point{X: 3, Y: 4}
	distFromOrigin := p.Distance
	fmt.Println(distFromOrigin(Point{0, 0}))

	// Closure in goroutine
	done := make(chan struct{})
	message := "hello"
	go func() {
		defer close(done)
		fmt.Println(message)
	}()
	<-done

	// Complex nested closures
	outer := func(prefix string) func(string) func() string {
		count := 0
		return func(middle string) func() string {
			return func() string {
				count++
				return fmt.Sprintf("%s-%s-%d", prefix, middle, count)
			}
		}
	}
	generator := outer("test")("item")
	fmt.Println(generator(), generator())
}

// Function type used as a strategy pattern
type SortStrategy func([]int) []int

func bubbleSort(data []int) []int {
	n := len(data)
	sorted := make([]int, n)
	copy(sorted, data)
	for i := 0; i < n-1; i++ {
		for j := 0; j < n-i-1; j++ {
			if sorted[j] > sorted[j+1] {
				sorted[j], sorted[j+1] = sorted[j+1], sorted[j]
			}
		}
	}
	return sorted
}

func insertionSort(data []int) []int {
	n := len(data)
	sorted := make([]int, n)
	copy(sorted, data)
	for i := 1; i < n; i++ {
		key := sorted[i]
		j := i - 1
		for j >= 0 && sorted[j] > key {
			sorted[j+1] = sorted[j]
			j--
		}
		sorted[j+1] = key
	}
	return sorted
}

// ---------------------------------------------------------------------------
// Section 20: Embedding and composition
// ---------------------------------------------------------------------------

// Interface embedding
type ReadWriteSeekCloser interface {
	io.Reader
	io.Writer
	io.Seeker
	io.Closer
}

// Struct embedding
type Animal struct {
	Name   string
	Age    int
	Weight float64
}

func (a Animal) Speak() string {
	return fmt.Sprintf("%s says something", a.Name)
}

func (a Animal) String() string {
	return fmt.Sprintf("%s (age: %d, weight: %.1f)", a.Name, a.Age, a.Weight)
}

type Dog struct {
	Animal
	Breed     string
	Tricks    []string
	isGoodBoy bool
}

func (d Dog) Speak() string {
	return fmt.Sprintf("%s says: Woof!", d.Name)
}

func (d Dog) Fetch(item string) string {
	return fmt.Sprintf("%s fetches the %s", d.Name, item)
}

type ServiceDog struct {
	Dog
	Handler     string
	Certificate string
	Tasks       []string
}

func (sd ServiceDog) Assist() string {
	return fmt.Sprintf("%s assists %s", sd.Name, sd.Handler)
}

// Multiple embedding
type LoggingServer struct {
	*Server
	*log.Logger
	auditLog []string
}

func (ls *LoggingServer) LogRequest(method, path string, status int) {
	entry := fmt.Sprintf("%s %s %s -> %d", time.Now().Format(time.RFC3339), method, path, status)
	ls.auditLog = append(ls.auditLog, entry)
	ls.Logger.Println(entry)
}

// Embedding interfaces in structs
type MockRepository struct {
	Repository
	GetFunc    func(ctx context.Context, id string) (interface{}, error)
	CreateFunc func(ctx context.Context, entity interface{}) error
}

func (m *MockRepository) Get(ctx context.Context, id string) (interface{}, error) {
	if m.GetFunc != nil {
		return m.GetFunc(ctx, id)
	}
	return nil, errors.New("not implemented")
}

func (m *MockRepository) Create(ctx context.Context, entity interface{}) error {
	if m.CreateFunc != nil {
		return m.CreateFunc(ctx, entity)
	}
	return errors.New("not implemented")
}

// ---------------------------------------------------------------------------
// Section 21: Generics — advanced patterns
// ---------------------------------------------------------------------------

// Generic linked list
type Node[T any] struct {
	Value T
	Next  *Node[T]
}

type LinkedList[T any] struct {
	Head *Node[T]
	Tail *Node[T]
	Len  int
}

func (ll *LinkedList[T]) Append(value T) {
	node := &Node[T]{Value: value}
	if ll.Tail == nil {
		ll.Head = node
		ll.Tail = node
	} else {
		ll.Tail.Next = node
		ll.Tail = node
	}
	ll.Len++
}

func (ll *LinkedList[T]) ToSlice() []T {
	result := make([]T, 0, ll.Len)
	current := ll.Head
	for current != nil {
		result = append(result, current.Value)
		current = current.Next
	}
	return result
}

func (ll *LinkedList[T]) ForEach(fn func(T)) {
	current := ll.Head
	for current != nil {
		fn(current.Value)
		current = current.Next
	}
}

// Generic stack
type Stack[T any] struct {
	items []T
}

func (s *Stack[T]) Push(item T) {
	s.items = append(s.items, item)
}

func (s *Stack[T]) Pop() (T, bool) {
	if len(s.items) == 0 {
		var zero T
		return zero, false
	}
	item := s.items[len(s.items)-1]
	s.items = s.items[:len(s.items)-1]
	return item, true
}

func (s *Stack[T]) Peek() (T, bool) {
	if len(s.items) == 0 {
		var zero T
		return zero, false
	}
	return s.items[len(s.items)-1], true
}

func (s *Stack[T]) IsEmpty() bool {
	return len(s.items) == 0
}

// Generic binary tree
type TreeNode[T Ordered] struct {
	Value T
	Left  *TreeNode[T]
	Right *TreeNode[T]
}

type BinarySearchTree[T Ordered] struct {
	Root *TreeNode[T]
	Size int
}

func (bst *BinarySearchTree[T]) Insert(value T) {
	bst.Root = bst.insertNode(bst.Root, value)
	bst.Size++
}

func (bst *BinarySearchTree[T]) insertNode(node *TreeNode[T], value T) *TreeNode[T] {
	if node == nil {
		return &TreeNode[T]{Value: value}
	}
	if value < node.Value {
		node.Left = bst.insertNode(node.Left, value)
	} else if value > node.Value {
		node.Right = bst.insertNode(node.Right, value)
	}
	return node
}

func (bst *BinarySearchTree[T]) Search(value T) bool {
	return bst.searchNode(bst.Root, value)
}

func (bst *BinarySearchTree[T]) searchNode(node *TreeNode[T], value T) bool {
	if node == nil {
		return false
	}
	if value == node.Value {
		return true
	}
	if value < node.Value {
		return bst.searchNode(node.Left, value)
	}
	return bst.searchNode(node.Right, value)
}

func (bst *BinarySearchTree[T]) InOrder() []T {
	var result []T
	var traverse func(*TreeNode[T])
	traverse = func(node *TreeNode[T]) {
		if node == nil {
			return
		}
		traverse(node.Left)
		result = append(result, node.Value)
		traverse(node.Right)
	}
	traverse(bst.Root)
	return result
}

// Generic functional utilities
func Reduce[T any, U any](slice []T, initial U, fn func(U, T) U) U {
	result := initial
	for _, v := range slice {
		result = fn(result, v)
	}
	return result
}

func Filter[T any](slice []T, predicate func(T) bool) []T {
	var result []T
	for _, v := range slice {
		if predicate(v) {
			result = append(result, v)
		}
	}
	return result
}

func ForEach[T any](slice []T, fn func(int, T)) {
	for i, v := range slice {
		fn(i, v)
	}
}

func Chunk[T any](slice []T, size int) [][]T {
	if size <= 0 {
		return nil
	}
	var chunks [][]T
	for i := 0; i < len(slice); i += size {
		end := i + size
		if end > len(slice) {
			end = len(slice)
		}
		chunks = append(chunks, slice[i:end])
	}
	return chunks
}

func Zip[T any, U any](a []T, b []U) []Pair[T, U] {
	minLen := len(a)
	if len(b) < minLen {
		minLen = len(b)
	}
	result := make([]Pair[T, U], minLen)
	for i := 0; i < minLen; i++ {
		result[i] = Pair[T, U]{Key: a[i], Value: b[i]}
	}
	return result
}

// Generic option/maybe type
type Option[T any] struct {
	value *T
}

func Some[T any](value T) Option[T] {
	return Option[T]{value: &value}
}

func None[T any]() Option[T] {
	return Option[T]{value: nil}
}

func (o Option[T]) IsSome() bool {
	return o.value != nil
}

func (o Option[T]) IsNone() bool {
	return o.value == nil
}

func (o Option[T]) Unwrap() T {
	if o.value == nil {
		panic("unwrap called on None")
	}
	return *o.value
}

func (o Option[T]) UnwrapOr(defaultValue T) T {
	if o.value == nil {
		return defaultValue
	}
	return *o.value
}

func (o Option[T]) Map(fn func(T) T) Option[T] {
	if o.value == nil {
		return None[T]()
	}
	return Some(fn(*o.value))
}

// ---------------------------------------------------------------------------
// Section 22: Context patterns
// ---------------------------------------------------------------------------

type contextKey string

const (
	requestIDKey contextKey = "request_id"
	userKey      contextKey = "user"
	traceKey     contextKey = "trace"
)

func WithRequestID(ctx context.Context, id string) context.Context {
	return context.WithValue(ctx, requestIDKey, id)
}

func RequestIDFrom(ctx context.Context) (string, bool) {
	id, ok := ctx.Value(requestIDKey).(string)
	return id, ok
}

func WithUser(ctx context.Context, user *User) context.Context {
	return context.WithValue(ctx, userKey, user)
}

func UserFrom(ctx context.Context) (*User, bool) {
	user, ok := ctx.Value(userKey).(*User)
	return user, ok
}

func demonstrateContext() {
	// Context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Context with deadline
	deadline := time.Now().Add(10 * time.Second)
	ctx2, cancel2 := context.WithDeadline(ctx, deadline)
	defer cancel2()

	// Context with cancel
	ctx3, cancel3 := context.WithCancel(ctx2)
	defer cancel3()

	// Context with value chain
	ctx4 := WithRequestID(ctx3, "req-12345")
	ctx5 := WithUser(ctx4, &User{ID: "user-1", Name: "Test"})

	// Using context for cancellation
	go func() {
		select {
		case <-ctx5.Done():
			fmt.Println("operation cancelled:", ctx5.Err())
		case <-time.After(3 * time.Second):
			fmt.Println("operation completed")
		}
	}()

	// Context with cause (Go 1.20+)
	ctx6, cancel6 := context.WithCancelCause(context.Background())
	cancel6(errors.New("custom reason"))
	fmt.Println("cause:", context.Cause(ctx6))
}

// ---------------------------------------------------------------------------
// Section 23: Reflection
// ---------------------------------------------------------------------------

func demonstrateReflection() {
	// Type inspection
	var x float64 = 3.14
	t := reflect.TypeOf(x)
	fmt.Println("type:", t)
	fmt.Println("kind:", t.Kind())

	// Value inspection
	v := reflect.ValueOf(x)
	fmt.Println("value:", v)
	fmt.Println("float:", v.Float())

	// Struct field inspection
	user := User{ID: "1", Name: "Alice", Email: "alice@example.com"}
	ut := reflect.TypeOf(user)
	for i := 0; i < ut.NumField(); i++ {
		field := ut.Field(i)
		value := reflect.ValueOf(user).Field(i)
		fmt.Printf("  %s (%s) = %v\n", field.Name, field.Type, value)
	}

	// Setting values via reflection
	ptr := reflect.ValueOf(&x).Elem()
	if ptr.CanSet() {
		ptr.SetFloat(6.28)
	}

	// Dynamic method calls
	method := reflect.ValueOf(user).MethodByName("String")
	if method.IsValid() {
		results := method.Call(nil)
		fmt.Println("method result:", results[0])
	}

	// Creating values via reflection
	sliceType := reflect.SliceOf(reflect.TypeOf(""))
	slice := reflect.MakeSlice(sliceType, 0, 5)
	slice = reflect.Append(slice, reflect.ValueOf("hello"))
	slice = reflect.Append(slice, reflect.ValueOf("world"))
	fmt.Println("reflected slice:", slice.Interface())

	// Map via reflection
	mapType := reflect.MapOf(reflect.TypeOf(""), reflect.TypeOf(0))
	m := reflect.MakeMap(mapType)
	m.SetMapIndex(reflect.ValueOf("key"), reflect.ValueOf(42))
	fmt.Println("reflected map:", m.Interface())

	// Struct tag inspection
	type Tagged struct {
		Name  string `json:"name" validate:"required"`
		Email string `json:"email" validate:"email"`
		Age   int    `json:"age,omitempty" validate:"min=0,max=150"`
	}
	taggedType := reflect.TypeOf(Tagged{})
	for i := 0; i < taggedType.NumField(); i++ {
		field := taggedType.Field(i)
		jsonTag := field.Tag.Get("json")
		validateTag := field.Tag.Get("validate")
		fmt.Printf("  %s: json=%q validate=%q\n", field.Name, jsonTag, validateTag)
	}

	// Interface satisfaction check
	var _ fmt.Stringer = user
	stringerType := reflect.TypeOf((*fmt.Stringer)(nil)).Elem()
	fmt.Println("User implements Stringer:", reflect.TypeOf(user).Implements(stringerType))
}

// ---------------------------------------------------------------------------
// Section 24: JSON marshaling/unmarshaling
// ---------------------------------------------------------------------------

type APIResponse struct {
	Status string          `json:"status"`
	Data   json.RawMessage `json:"data,omitempty"`
	Error  *APIError       `json:"error,omitempty"`
	Meta   ResponseMeta    `json:"meta"`
}

type APIError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Details []struct {
		Field   string `json:"field"`
		Message string `json:"message"`
	} `json:"details,omitempty"`
}

type ResponseMeta struct {
	RequestID  string    `json:"request_id"`
	Timestamp  time.Time `json:"timestamp"`
	Duration   string    `json:"duration"`
	Pagination *struct {
		Page       int `json:"page"`
		PerPage    int `json:"per_page"`
		Total      int `json:"total"`
		TotalPages int `json:"total_pages"`
	} `json:"pagination,omitempty"`
}

// Custom JSON marshaling
type Duration time.Duration

func (d Duration) MarshalJSON() ([]byte, error) {
	return json.Marshal(time.Duration(d).String())
}

func (d *Duration) UnmarshalJSON(b []byte) error {
	var s string
	if err := json.Unmarshal(b, &s); err != nil {
		return err
	}
	dur, err := time.ParseDuration(s)
	if err != nil {
		return err
	}
	*d = Duration(dur)
	return nil
}

// JSON with interface field
type Event struct {
	Type      string          `json:"type"`
	Timestamp time.Time       `json:"timestamp"`
	Payload   json.RawMessage `json:"payload"`
}

func (e *Event) ParsePayload() (interface{}, error) {
	switch e.Type {
	case "user.created":
		var payload struct {
			UserID string `json:"user_id"`
			Email  string `json:"email"`
		}
		if err := json.Unmarshal(e.Payload, &payload); err != nil {
			return nil, err
		}
		return payload, nil
	case "order.placed":
		var payload struct {
			OrderID string  `json:"order_id"`
			Amount  float64 `json:"amount"`
			Items   int     `json:"items"`
		}
		if err := json.Unmarshal(e.Payload, &payload); err != nil {
			return nil, err
		}
		return payload, nil
	default:
		var payload map[string]interface{}
		if err := json.Unmarshal(e.Payload, &payload); err != nil {
			return nil, err
		}
		return payload, nil
	}
}

func demonstrateJSON() {
	// Marshal
	response := APIResponse{
		Status: "success",
		Meta: ResponseMeta{
			RequestID: "req-123",
			Timestamp: time.Now(),
			Duration:  "42ms",
		},
	}
	data, _ := json.MarshalIndent(response, "", "  ")
	fmt.Println(string(data))

	// Unmarshal into struct
	jsonStr := `{"status":"ok","data":{"id":"1","name":"test"}}`
	var resp APIResponse
	json.Unmarshal([]byte(jsonStr), &resp)

	// Unmarshal into map
	var generic map[string]interface{}
	json.Unmarshal([]byte(jsonStr), &generic)

	// Streaming JSON with decoder
	reader := strings.NewReader(`{"a":1}{"b":2}{"c":3}`)
	decoder := json.NewDecoder(reader)
	for decoder.More() {
		var obj map[string]int
		if err := decoder.Decode(&obj); err != nil {
			break
		}
		fmt.Println(obj)
	}

	// JSON encoder to writer
	var buf bytes.Buffer
	encoder := json.NewEncoder(&buf)
	encoder.SetIndent("", "  ")
	encoder.SetEscapeHTML(false)
	encoder.Encode(response)
}

// ---------------------------------------------------------------------------
// Section 25: HTTP handlers and middleware
// ---------------------------------------------------------------------------

// Basic handler
func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "healthy"})
}

// Handler with complex logic
func userHandler(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		id := r.URL.Query().Get("id")
		if id == "" {
			http.Error(w, "missing id parameter", http.StatusBadRequest)
			return
		}
		user, err := fetchUser(r.Context(), id)
		if err != nil {
			if errors.Is(err, ErrNotFound) {
				http.Error(w, "user not found", http.StatusNotFound)
				return
			}
			http.Error(w, "internal error", http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(user)

	case http.MethodPost:
		var user User
		if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
			http.Error(w, "invalid request body", http.StatusBadRequest)
			return
		}
		defer r.Body.Close()

		if user.Name == "" {
			http.Error(w, "name is required", http.StatusBadRequest)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(user)

	case http.MethodDelete:
		id := r.URL.Query().Get("id")
		if id == "" {
			http.Error(w, "missing id", http.StatusBadRequest)
			return
		}
		w.WriteHeader(http.StatusNoContent)

	default:
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
	}
}

// Middleware functions
func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		wrapped := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}

		next.ServeHTTP(wrapped, r)

		log.Printf("%s %s %d %s",
			r.Method, r.URL.Path, wrapped.statusCode, time.Since(start))
	})
}

func authMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		token := r.Header.Get("Authorization")
		if token == "" {
			http.Error(w, "unauthorized", http.StatusUnauthorized)
			return
		}

		if !strings.HasPrefix(token, "Bearer ") {
			http.Error(w, "invalid token format", http.StatusUnauthorized)
			return
		}

		userID := validateToken(strings.TrimPrefix(token, "Bearer "))
		if userID == "" {
			http.Error(w, "invalid token", http.StatusUnauthorized)
			return
		}

		ctx := WithUser(r.Context(), &User{ID: userID})
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func corsMiddleware(allowedOrigins []string) Middleware {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			origin := r.Header.Get("Origin")
			for _, allowed := range allowedOrigins {
				if origin == allowed {
					w.Header().Set("Access-Control-Allow-Origin", origin)
					w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
					w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
					w.Header().Set("Access-Control-Max-Age", "86400")
					break
				}
			}

			if r.Method == http.MethodOptions {
				w.WriteHeader(http.StatusNoContent)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}

func rateLimitMiddleware(requestsPerSecond float64) Middleware {
	limiter := &rateLimiter{
		rate:     requestsPerSecond,
		tokens:   requestsPerSecond,
		lastTime: time.Now(),
	}

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if !limiter.Allow() {
				w.Header().Set("Retry-After", "1")
				http.Error(w, "rate limit exceeded", http.StatusTooManyRequests)
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}

func recoveryMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				buf := make([]byte, 4096)
				n := runtime.Stack(buf, false)
				log.Printf("panic recovered: %v\n%s", err, buf[:n])
				http.Error(w, "internal server error", http.StatusInternalServerError)
			}
		}()
		next.ServeHTTP(w, r)
	})
}

// Middleware chain
func chainMiddleware(handler http.Handler, middlewares ...Middleware) http.Handler {
	for i := len(middlewares) - 1; i >= 0; i-- {
		handler = middlewares[i](handler)
	}
	return handler
}

type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

type rateLimiter struct {
	mu       sync.Mutex
	rate     float64
	tokens   float64
	lastTime time.Time
}

func (rl *rateLimiter) Allow() bool {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	now := time.Now()
	elapsed := now.Sub(rl.lastTime).Seconds()
	rl.tokens += elapsed * rl.rate
	if rl.tokens > rl.rate {
		rl.tokens = rl.rate
	}
	rl.lastTime = now

	if rl.tokens >= 1 {
		rl.tokens--
		return true
	}
	return false
}

func validateToken(token string) string {
	return "user-1"
}

// HTTP server setup
func setupServer() *http.ServeMux {
	mux := http.NewServeMux()

	mux.HandleFunc("/health", healthHandler)
	mux.HandleFunc("/users", userHandler)

	mux.HandleFunc("/api/data", func(w http.ResponseWriter, r *http.Request) {
		data := map[string]interface{}{
			"items": []map[string]interface{}{
				{"id": 1, "name": "item1"},
				{"id": 2, "name": "item2"},
			},
			"total": 2,
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(data)
	})

	return mux
}

// ---------------------------------------------------------------------------
// Section 26: Testing patterns
// ---------------------------------------------------------------------------

// Table-driven test
func TestAdd(t *testing.T) {
	tests := []struct {
		name     string
		a, b     int
		expected int
	}{
		{"positive", 2, 3, 5},
		{"negative", -1, -2, -3},
		{"zero", 0, 0, 0},
		{"mixed", -1, 5, 4},
		{"large", 1000000, 2000000, 3000000},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := add(tt.a, tt.b)
			if result != tt.expected {
				t.Errorf("add(%d, %d) = %d; want %d", tt.a, tt.b, result, tt.expected)
			}
		})
	}
}

// Test with setup and teardown
func TestServer(t *testing.T) {
	// Setup
	cfg := Config{
		Host:    "localhost",
		Port:    0, // random port
		Timeout: 5 * time.Second,
	}
	_ = cfg

	t.Run("health check", func(t *testing.T) {
		t.Parallel()
		// test implementation
	})

	t.Run("user CRUD", func(t *testing.T) {
		t.Run("create", func(t *testing.T) {
			// nested subtest
		})
		t.Run("read", func(t *testing.T) {
			// nested subtest
		})
		t.Run("update", func(t *testing.T) {
			// nested subtest
		})
		t.Run("delete", func(t *testing.T) {
			// nested subtest
		})
	})

	// Cleanup
	t.Cleanup(func() {
		// shutdown server, close connections
	})
}

// Benchmark
func BenchmarkAdd(b *testing.B) {
	for i := 0; i < b.N; i++ {
		add(i, i+1)
	}
}

func BenchmarkSum(b *testing.B) {
	data := make([]int, 1000)
	for i := range data {
		data[i] = i
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		sum(data...)
	}
}

// Fuzz test
func FuzzParseHostPort(f *testing.F) {
	f.Add("localhost:8080")
	f.Add("0.0.0.0:0")
	f.Add("example.com:443")

	f.Fuzz(func(t *testing.T, addr string) {
		host, port, err := parseHostPort(addr)
		if err != nil {
			return
		}
		if host == "" {
			t.Error("empty host")
		}
		if port < 0 || port > 65535 {
			t.Errorf("invalid port: %d", port)
		}
	})
}

// Example test (testable example)
func ExampleAdd() {
	fmt.Println(add(2, 3))
	// Output: 5
}

func ExamplePoint_Distance() {
	p1 := Point{0, 0}
	p2 := Point{3, 4}
	fmt.Println(p1.Distance(p2))
	// Output: 5
}

// Test helpers
func assertEqual(t *testing.T, got, want interface{}) {
	t.Helper()
	if !reflect.DeepEqual(got, want) {
		t.Errorf("got %v, want %v", got, want)
	}
}

func assertNoError(t *testing.T, err error) {
	t.Helper()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func assertError(t *testing.T, err error) {
	t.Helper()
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}

func assertPanics(t *testing.T, fn func()) {
	t.Helper()
	defer func() {
		if r := recover(); r == nil {
			t.Fatal("expected panic, but didn't panic")
		}
	}()
	fn()
}

// ---------------------------------------------------------------------------
// Section 27: Goto and labels
// ---------------------------------------------------------------------------

func demonstrateGoto() {
	i := 0
start:
	if i >= 10 {
		goto end
	}
	fmt.Println(i)
	i++
	goto start
end:
	fmt.Println("done")

	// Label used with break in nested loops
	matrix := [][]int{{1, 2, 3}, {4, 5, 6}, {7, 8, 9}}
search:
	for r, row := range matrix {
		for c, val := range row {
			if val == 5 {
				fmt.Printf("found 5 at [%d][%d]\n", r, c)
				break search
			}
		}
	}
}

// ---------------------------------------------------------------------------
// Section 28: Unsafe operations
// ---------------------------------------------------------------------------

func demonstrateUnsafe() {
	// sizeof
	var x int64
	fmt.Println("size of int64:", unsafe.Sizeof(x))

	// alignof
	type sample struct {
		a bool
		b int64
		c bool
	}
	var s sample
	fmt.Println("alignment of sample:", unsafe.Alignof(s))
	fmt.Println("offset of b:", unsafe.Offsetof(s.b))
	fmt.Println("offset of c:", unsafe.Offsetof(s.c))

	// Pointer arithmetic (advanced, dangerous)
	arr := [5]int{10, 20, 30, 40, 50}
	ptr := unsafe.Pointer(&arr[0])
	for i := 0; i < 5; i++ {
		val := (*int)(unsafe.Pointer(uintptr(ptr) + uintptr(i)*unsafe.Sizeof(arr[0])))
		fmt.Println(*val)
	}

	// Convert between incompatible types
	type MyInt int
	var myVal MyInt = 42
	regularInt := *(*int)(unsafe.Pointer(&myVal))
	fmt.Println(regularInt)
}

// ---------------------------------------------------------------------------
// Section 29: Build tags and conditional compilation
// ---------------------------------------------------------------------------

// Note: Build tags would normally be at the top of the file.
// These are shown here for completeness but wouldn't compile with the rest.

// //go:build linux && amd64
// //go:build !windows

// ---------------------------------------------------------------------------
// Section 30: Compiler directives and pragmas
// ---------------------------------------------------------------------------

//go:noinline
func noInlineFunction() int {
	return 42
}

//go:nosplit
func noSplitFunction() {
	// This function won't grow the stack
}

// go:linkname is another directive (not shown as it needs special imports)

// Blank identifier patterns
var (
	_ io.Reader    = (*os.File)(nil) // compile-time interface check
	_ fmt.Stringer = Point{}         // compile-time interface check
	_              = fmt.Println     // keep import for side effects
)

// ---------------------------------------------------------------------------
// Section 31: Signal handling and graceful shutdown
// ---------------------------------------------------------------------------

func demonstrateSignalHandling() {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	// Alternative: using signal.Notify
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM, syscall.SIGHUP)

	go func() {
		for {
			select {
			case sig := <-sigCh:
				switch sig {
				case syscall.SIGINT, syscall.SIGTERM:
					fmt.Println("shutting down...")
					stop()
					return
				case syscall.SIGHUP:
					fmt.Println("reloading config...")
				}
			case <-ctx.Done():
				return
			}
		}
	}()

	<-ctx.Done()
	fmt.Println("shutdown complete")
}

func gracefulShutdown(srv *http.Server) error {
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	srv.SetKeepAlivesEnabled(false)
	if err := srv.Shutdown(ctx); err != nil {
		return fmt.Errorf("server shutdown: %w", err)
	}
	return nil
}

// ---------------------------------------------------------------------------
// Section 32: File I/O patterns
// ---------------------------------------------------------------------------

func demonstrateFileIO() {
	// Read entire file
	content, err := os.ReadFile("input.txt")
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(string(content))

	// Write entire file
	err = os.WriteFile("output.txt", []byte("hello\n"), 0644)
	if err != nil {
		log.Fatal(err)
	}

	// Buffered reading
	file, err := os.Open("large.txt")
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	scanner.Buffer(make([]byte, 1024*1024), 1024*1024)
	lineNum := 0
	for scanner.Scan() {
		lineNum++
		line := scanner.Text()
		if strings.Contains(line, "ERROR") {
			fmt.Printf("line %d: %s\n", lineNum, line)
		}
	}
	if err := scanner.Err(); err != nil {
		log.Fatal(err)
	}

	// Buffered writing
	outFile, err := os.Create("buffered.txt")
	if err != nil {
		log.Fatal(err)
	}
	defer outFile.Close()

	writer := bufio.NewWriter(outFile)
	for i := 0; i < 1000; i++ {
		fmt.Fprintf(writer, "line %d\n", i)
	}
	writer.Flush()

	// Walking a directory
	err = filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() && info.Name() == ".git" {
			return filepath.SkipDir
		}
		if !info.IsDir() && strings.HasSuffix(info.Name(), ".go") {
			fmt.Println(path)
		}
		return nil
	})
	if err != nil {
		log.Fatal(err)
	}

	// Temp file
	tmpFile, err := os.CreateTemp("", "prefix-*.txt")
	if err != nil {
		log.Fatal(err)
	}
	defer os.Remove(tmpFile.Name())
	defer tmpFile.Close()

	tmpFile.WriteString("temporary content\n")

	// Temp directory
	tmpDir, err := os.MkdirTemp("", "testdir-*")
	if err != nil {
		log.Fatal(err)
	}
	defer os.RemoveAll(tmpDir)
}

// ---------------------------------------------------------------------------
// Section 33: String manipulation
// ---------------------------------------------------------------------------

func demonstrateStrings() {
	s := "Hello, World! 世界"

	// Basic operations
	fmt.Println(strings.ToUpper(s))
	fmt.Println(strings.ToLower(s))
	fmt.Println(strings.TrimSpace("  hello  "))
	fmt.Println(strings.TrimPrefix(s, "Hello, "))
	fmt.Println(strings.TrimSuffix(s, "!"))
	fmt.Println(strings.Contains(s, "World"))
	fmt.Println(strings.HasPrefix(s, "Hello"))
	fmt.Println(strings.HasSuffix(s, "界"))
	fmt.Println(strings.Count(s, "l"))
	fmt.Println(strings.Index(s, "World"))
	fmt.Println(strings.Replace(s, "World", "Go", 1))
	fmt.Println(strings.ReplaceAll(s, "l", "L"))

	// Split and join
	parts := strings.Split("a,b,c,d", ",")
	fmt.Println(strings.Join(parts, " | "))

	fields := strings.Fields("  hello   world   ")
	fmt.Println(fields)

	// String builder
	var builder strings.Builder
	for i := 0; i < 100; i++ {
		builder.WriteString("chunk")
		builder.WriteByte(' ')
	}
	result := builder.String()
	fmt.Println(len(result))

	// Rune operations
	fmt.Println(utf8.RuneCountInString(s))
	for _, r := range s {
		fmt.Printf("%c ", r)
	}
	fmt.Println()

	// String conversion
	num := strconv.Itoa(42)
	fmt.Println(num)
	parsed, _ := strconv.Atoi("42")
	fmt.Println(parsed)
	floatStr := strconv.FormatFloat(3.14, 'f', 2, 64)
	fmt.Println(floatStr)

	// Byte slice and string
	bs := []byte(s)
	s2 := string(bs)
	fmt.Println(s2)

	// Multi-line string building
	query := strings.Join([]string{
		"SELECT u.id, u.name, u.email",
		"FROM users u",
		"JOIN orders o ON o.user_id = u.id",
		"WHERE o.total > $1",
		"ORDER BY o.created_at DESC",
		"LIMIT $2",
	}, "\n")
	fmt.Println(query)
}

// ---------------------------------------------------------------------------
// Section 34: Regex patterns
// ---------------------------------------------------------------------------

func demonstrateRegex() {
	// Compile and match
	re := regexp.MustCompile(`(\w+)@(\w+)\.(\w+)`)
	fmt.Println(re.MatchString("user@example.com"))

	// Find
	match := re.FindString("contact user@example.com for info")
	fmt.Println("found:", match)

	// Find submatch
	groups := re.FindStringSubmatch("user@example.com")
	for i, g := range groups {
		fmt.Printf("  group %d: %s\n", i, g)
	}

	// Find all
	text := "emails: alice@foo.com, bob@bar.org, carol@baz.net"
	all := re.FindAllString(text, -1)
	fmt.Println("all matches:", all)

	// Replace
	replaced := re.ReplaceAllString(text, "***@***.***")
	fmt.Println("replaced:", replaced)

	// Replace with function
	result := re.ReplaceAllStringFunc(text, func(s string) string {
		return strings.ToUpper(s)
	})
	fmt.Println("func replaced:", result)

	// Named groups
	namedRe := regexp.MustCompile(`(?P<year>\d{4})-(?P<month>\d{2})-(?P<day>\d{2})`)
	match2 := namedRe.FindStringSubmatch("2024-01-15")
	for i, name := range namedRe.SubexpNames() {
		if i > 0 && name != "" {
			fmt.Printf("  %s: %s\n", name, match2[i])
		}
	}
}

// ---------------------------------------------------------------------------
// Section 35: Crypto and randomness
// ---------------------------------------------------------------------------

func demonstrateCrypto() {
	// Crypto random bytes
	randomBytes := make([]byte, 32)
	if _, err := rand.Read(randomBytes); err != nil {
		log.Fatal(err)
	}
	fmt.Printf("random: %x\n", randomBytes)

	// Random big int
	max := new(big.Int).SetInt64(1000)
	n, err := rand.Int(rand.Reader, max)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("random int:", n)

	// Generate a random token
	token := make([]byte, 32)
	rand.Read(token)
	fmt.Printf("token: %x\n", token)
}

// ---------------------------------------------------------------------------
// Section 36: Complex function with every control flow
// ---------------------------------------------------------------------------

// This function deliberately combines many constructs for Treesitter testing
func complexFunction(
	ctx context.Context,
	items []interface{},
	config map[string]interface{},
	callback func(string) error,
) (result []string, totalCount int, err error) {
	// Defer with named returns
	defer func() {
		if r := recover(); r != nil {
			err = fmt.Errorf("panic: %v", r)
			result = nil
			totalCount = 0
		}
	}()

	// Variable declarations
	var (
		processed int
		skipped   int
		retries   int
		maxRetry  = 3
		mu        sync.Mutex
		wg        sync.WaitGroup
		errCh     = make(chan error, len(items))
		resultCh  = make(chan string, len(items))
	)

	// Short variable declaration
	timeout := time.After(30 * time.Second)
	ticker := time.NewTicker(100 * time.Millisecond)
	defer ticker.Stop()

	// Type assertion
	if v, ok := config["verbose"].(bool); ok && v {
		logMessage("debug", "verbose mode enabled")
	}

	// Range over items with goroutines
	for i, item := range items {
		wg.Add(1)
		go func(index int, val interface{}) {
			defer wg.Done()

			// Type switch inside goroutine
			var strVal string
			switch v := val.(type) {
			case string:
				strVal = v
			case int:
				strVal = strconv.Itoa(v)
			case float64:
				strVal = strconv.FormatFloat(v, 'f', -1, 64)
			case fmt.Stringer:
				strVal = v.String()
			case nil:
				errCh <- fmt.Errorf("item %d is nil", index)
				return
			default:
				strVal = fmt.Sprintf("%v", v)
			}

			// Retry loop
			for attempt := 0; attempt <= maxRetry; attempt++ {
				if attempt > 0 {
					select {
					case <-ctx.Done():
						errCh <- ctx.Err()
						return
					case <-time.After(time.Duration(attempt*100) * time.Millisecond):
					}
				}

				if err := callback(strVal); err != nil {
					if attempt == maxRetry {
						errCh <- fmt.Errorf("item %d failed after %d retries: %w", index, maxRetry, err)
						mu.Lock()
						skipped++
						mu.Unlock()
						return
					}
					mu.Lock()
					retries++
					mu.Unlock()
					continue
				}

				// Success
				mu.Lock()
				processed++
				mu.Unlock()
				resultCh <- strVal
				return
			}
		}(i, item)
	}

	// Wait for all goroutines in a separate goroutine
	go func() {
		wg.Wait()
		close(resultCh)
		close(errCh)
	}()

	// Collect results with select
	var errs MultiError
collectLoop:
	for {
		select {
		case <-ctx.Done():
			return nil, 0, ctx.Err()
		case <-timeout:
			return nil, 0, errors.New("operation timed out")
		case <-ticker.C:
			mu.Lock()
			current := processed
			mu.Unlock()
			logMessage("info", fmt.Sprintf("progress: %d/%d", current, len(items)))
		case r, ok := <-resultCh:
			if !ok {
				break collectLoop
			}
			result = append(result, r)
		case e, ok := <-errCh:
			if !ok {
				continue
			}
			errs.Add(e)
		}
	}

	// Final processing with if chains
	totalCount = processed
	if errs.HasErrors() {
		if skipped > len(items)/2 {
			return nil, 0, fmt.Errorf("too many failures: %w", &errs)
		}
		logMessage("warn", fmt.Sprintf("completed with %d errors", len(errs.errors)))
	}

	// Sort results
	sort.Strings(result)

	// Log summary
	logMessage("info", fmt.Sprintf(
		"processed=%d skipped=%d retries=%d total=%d",
		processed, skipped, retries, len(items),
	))

	return result, totalCount, nil
}

// ---------------------------------------------------------------------------
// Section 37: Complex struct with many method types
// ---------------------------------------------------------------------------

type TaskRunner struct {
	name       string
	tasks      []*Task
	mu         sync.RWMutex
	ctx        context.Context
	cancel     context.CancelFunc
	wg         sync.WaitGroup
	sem        *Semaphore
	results    chan TaskResult
	errors     chan error
	hooks      TaskHooks
	middleware []TaskMiddleware
	started    atomic.Bool
	metrics    struct {
		total     atomic.Int64
		completed atomic.Int64
		failed    atomic.Int64
		duration  atomic.Int64
	}
}

type Task struct {
	ID        string
	Name      string
	Priority  int
	Fn        func(context.Context) (interface{}, error)
	Timeout   time.Duration
	Retries   int
	Tags      []string
	DependsOn []string
}

type TaskResult struct {
	TaskID   string
	Value    interface{}
	Duration time.Duration
	Attempts int
	Error    error
}

type TaskHooks struct {
	BeforeRun  func(*Task) error
	AfterRun   func(*Task, TaskResult)
	OnError    func(*Task, error)
	OnComplete func([]TaskResult)
}

type TaskMiddleware func(func(context.Context) (interface{}, error)) func(context.Context) (interface{}, error)

func NewTaskRunner(name string, concurrency int) *TaskRunner {
	ctx, cancel := context.WithCancel(context.Background())
	return &TaskRunner{
		name:    name,
		ctx:     ctx,
		cancel:  cancel,
		sem:     NewSemaphore(concurrency),
		results: make(chan TaskResult, 100),
		errors:  make(chan error, 100),
	}
}

func (tr *TaskRunner) AddTask(task *Task) {
	tr.mu.Lock()
	defer tr.mu.Unlock()
	tr.tasks = append(tr.tasks, task)
}

func (tr *TaskRunner) AddMiddleware(mw TaskMiddleware) {
	tr.mu.Lock()
	defer tr.mu.Unlock()
	tr.middleware = append(tr.middleware, mw)
}

func (tr *TaskRunner) SetHooks(hooks TaskHooks) {
	tr.mu.Lock()
	defer tr.mu.Unlock()
	tr.hooks = hooks
}

func (tr *TaskRunner) Run(ctx context.Context) ([]TaskResult, error) {
	if !tr.started.CompareAndSwap(false, true) {
		return nil, errors.New("already running")
	}
	defer tr.started.Store(false)

	tr.mu.RLock()
	tasks := make([]*Task, len(tr.tasks))
	copy(tasks, tr.tasks)
	tr.mu.RUnlock()

	// Sort by priority
	sort.Slice(tasks, func(i, j int) bool {
		return tasks[i].Priority > tasks[j].Priority
	})

	var results []TaskResult
	var resultsMu sync.Mutex

	for _, task := range tasks {
		tr.wg.Add(1)
		tr.metrics.total.Add(1)

		go func(t *Task) {
			defer tr.wg.Done()

			tr.sem.Acquire()
			defer tr.sem.Release()

			// Run hooks
			if tr.hooks.BeforeRun != nil {
				if err := tr.hooks.BeforeRun(t); err != nil {
					tr.metrics.failed.Add(1)
					return
				}
			}

			// Apply middleware
			fn := t.Fn
			for i := len(tr.middleware) - 1; i >= 0; i-- {
				fn = tr.middleware[i](fn)
			}

			// Execute with timeout and retries
			result := tr.executeTask(ctx, t, fn)

			resultsMu.Lock()
			results = append(results, result)
			resultsMu.Unlock()

			if result.Error != nil {
				tr.metrics.failed.Add(1)
				if tr.hooks.OnError != nil {
					tr.hooks.OnError(t, result.Error)
				}
			} else {
				tr.metrics.completed.Add(1)
			}

			if tr.hooks.AfterRun != nil {
				tr.hooks.AfterRun(t, result)
			}
		}(task)
	}

	tr.wg.Wait()

	if tr.hooks.OnComplete != nil {
		tr.hooks.OnComplete(results)
	}

	return results, nil
}

func (tr *TaskRunner) executeTask(
	ctx context.Context,
	task *Task,
	fn func(context.Context) (interface{}, error),
) TaskResult {
	start := time.Now()
	result := TaskResult{TaskID: task.ID}

	for attempt := 0; attempt <= task.Retries; attempt++ {
		result.Attempts = attempt + 1

		// Create timeout context if specified
		var taskCtx context.Context
		var taskCancel context.CancelFunc
		if task.Timeout > 0 {
			taskCtx, taskCancel = context.WithTimeout(ctx, task.Timeout)
		} else {
			taskCtx, taskCancel = context.WithCancel(ctx)
		}

		// Run in goroutine to respect context cancellation
		valueCh := make(chan interface{}, 1)
		errCh := make(chan error, 1)

		go func() {
			defer func() {
				if r := recover(); r != nil {
					errCh <- fmt.Errorf("task panicked: %v", r)
				}
			}()
			v, err := fn(taskCtx)
			if err != nil {
				errCh <- err
			} else {
				valueCh <- v
			}
		}()

		select {
		case v := <-valueCh:
			taskCancel()
			result.Value = v
			result.Duration = time.Since(start)
			return result
		case err := <-errCh:
			taskCancel()
			result.Error = err
			if attempt < task.Retries {
				// Exponential backoff
				backoff := time.Duration(1<<uint(attempt)) * 100 * time.Millisecond
				select {
				case <-ctx.Done():
					result.Error = ctx.Err()
					result.Duration = time.Since(start)
					return result
				case <-time.After(backoff):
					continue
				}
			}
		case <-taskCtx.Done():
			taskCancel()
			result.Error = taskCtx.Err()
			if attempt < task.Retries {
				continue
			}
		}
	}

	result.Duration = time.Since(start)
	return result
}

func (tr *TaskRunner) Stop() {
	tr.cancel()
	tr.wg.Wait()
}

func (tr *TaskRunner) Metrics() map[string]int64 {
	return map[string]int64{
		"total":     tr.metrics.total.Load(),
		"completed": tr.metrics.completed.Load(),
		"failed":    tr.metrics.failed.Load(),
	}
}

// ---------------------------------------------------------------------------
// Section 38: Builder pattern
// ---------------------------------------------------------------------------

type QueryBuilder struct {
	table      string
	selects    []string
	wheres     []whereClause
	joins      []joinClause
	orderBy    []orderClause
	groupBy    []string
	having     string
	limit      int
	offset     int
	params     []interface{}
	paramIndex int
}

type whereClause struct {
	condition string
	operator  string
	value     interface{}
}

type joinClause struct {
	joinType string
	table    string
	on       string
}

type orderClause struct {
	column    string
	direction string
}

func NewQueryBuilder(table string) *QueryBuilder {
	return &QueryBuilder{
		table:  table,
		limit:  -1,
		offset: -1,
	}
}

func (qb *QueryBuilder) Select(columns ...string) *QueryBuilder {
	qb.selects = append(qb.selects, columns...)
	return qb
}

func (qb *QueryBuilder) Where(condition string, value interface{}) *QueryBuilder {
	qb.wheres = append(qb.wheres, whereClause{condition: condition, value: value})
	return qb
}

func (qb *QueryBuilder) Join(table, on string) *QueryBuilder {
	qb.joins = append(qb.joins, joinClause{joinType: "JOIN", table: table, on: on})
	return qb
}

func (qb *QueryBuilder) LeftJoin(table, on string) *QueryBuilder {
	qb.joins = append(qb.joins, joinClause{joinType: "LEFT JOIN", table: table, on: on})
	return qb
}

func (qb *QueryBuilder) OrderBy(column, direction string) *QueryBuilder {
	qb.orderBy = append(qb.orderBy, orderClause{column: column, direction: direction})
	return qb
}

func (qb *QueryBuilder) GroupBy(columns ...string) *QueryBuilder {
	qb.groupBy = append(qb.groupBy, columns...)
	return qb
}

func (qb *QueryBuilder) Having(condition string) *QueryBuilder {
	qb.having = condition
	return qb
}

func (qb *QueryBuilder) Limit(n int) *QueryBuilder {
	qb.limit = n
	return qb
}

func (qb *QueryBuilder) Offset(n int) *QueryBuilder {
	qb.offset = n
	return qb
}

func (qb *QueryBuilder) Build() (string, []interface{}) {
	var sb strings.Builder

	// SELECT
	sb.WriteString("SELECT ")
	if len(qb.selects) == 0 {
		sb.WriteString("*")
	} else {
		sb.WriteString(strings.Join(qb.selects, ", "))
	}

	// FROM
	sb.WriteString(" FROM ")
	sb.WriteString(qb.table)

	// JOINS
	for _, j := range qb.joins {
		sb.WriteString(" ")
		sb.WriteString(j.joinType)
		sb.WriteString(" ")
		sb.WriteString(j.table)
		sb.WriteString(" ON ")
		sb.WriteString(j.on)
	}

	// WHERE
	if len(qb.wheres) > 0 {
		sb.WriteString(" WHERE ")
		for i, w := range qb.wheres {
			if i > 0 {
				sb.WriteString(" AND ")
			}
			qb.paramIndex++
			sb.WriteString(fmt.Sprintf("%s $%d", w.condition, qb.paramIndex))
			qb.params = append(qb.params, w.value)
		}
	}

	// GROUP BY
	if len(qb.groupBy) > 0 {
		sb.WriteString(" GROUP BY ")
		sb.WriteString(strings.Join(qb.groupBy, ", "))
	}

	// HAVING
	if qb.having != "" {
		sb.WriteString(" HAVING ")
		sb.WriteString(qb.having)
	}

	// ORDER BY
	if len(qb.orderBy) > 0 {
		sb.WriteString(" ORDER BY ")
		clauses := make([]string, len(qb.orderBy))
		for i, o := range qb.orderBy {
			clauses[i] = fmt.Sprintf("%s %s", o.column, o.direction)
		}
		sb.WriteString(strings.Join(clauses, ", "))
	}

	// LIMIT
	if qb.limit >= 0 {
		qb.paramIndex++
		sb.WriteString(fmt.Sprintf(" LIMIT $%d", qb.paramIndex))
		qb.params = append(qb.params, qb.limit)
	}

	// OFFSET
	if qb.offset >= 0 {
		qb.paramIndex++
		sb.WriteString(fmt.Sprintf(" OFFSET $%d", qb.paramIndex))
		qb.params = append(qb.params, qb.offset)
	}

	return sb.String(), qb.params
}

// ---------------------------------------------------------------------------
// Section 39: State machine pattern
// ---------------------------------------------------------------------------

type State int

const (
	StateIdle State = iota
	StateConnecting
	StateConnected
	StateAuthenticating
	StateAuthenticated
	StateDisconnecting
	StateDisconnected
	StateError
)

func (s State) String() string {
	switch s {
	case StateIdle:
		return "idle"
	case StateConnecting:
		return "connecting"
	case StateConnected:
		return "connected"
	case StateAuthenticating:
		return "authenticating"
	case StateAuthenticated:
		return "authenticated"
	case StateDisconnecting:
		return "disconnecting"
	case StateDisconnected:
		return "disconnected"
	case StateError:
		return "error"
	default:
		return "unknown"
	}
}

type StateMachine struct {
	mu          sync.RWMutex
	current     State
	transitions map[State]map[State]func() error
	onEnter     map[State]func()
	onExit      map[State]func()
	history     []StateTransition
}

type StateTransition struct {
	From      State
	To        State
	Timestamp time.Time
	Error     error
}

func NewStateMachine(initial State) *StateMachine {
	return &StateMachine{
		current:     initial,
		transitions: make(map[State]map[State]func() error),
		onEnter:     make(map[State]func()),
		onExit:      make(map[State]func()),
	}
}

func (sm *StateMachine) AddTransition(from, to State, action func() error) {
	sm.mu.Lock()
	defer sm.mu.Unlock()

	if sm.transitions[from] == nil {
		sm.transitions[from] = make(map[State]func() error)
	}
	sm.transitions[from][to] = action
}

func (sm *StateMachine) OnEnter(state State, fn func()) {
	sm.mu.Lock()
	defer sm.mu.Unlock()
	sm.onEnter[state] = fn
}

func (sm *StateMachine) OnExit(state State, fn func()) {
	sm.mu.Lock()
	defer sm.mu.Unlock()
	sm.onExit[state] = fn
}

func (sm *StateMachine) Transition(to State) error {
	sm.mu.Lock()
	defer sm.mu.Unlock()

	from := sm.current
	transitions, ok := sm.transitions[from]
	if !ok {
		return fmt.Errorf("no transitions from state %s", from)
	}

	action, ok := transitions[to]
	if !ok {
		return fmt.Errorf("invalid transition: %s -> %s", from, to)
	}

	// Execute exit hook
	if exitFn, ok := sm.onExit[from]; ok {
		exitFn()
	}

	// Execute transition action
	transition := StateTransition{
		From:      from,
		To:        to,
		Timestamp: time.Now(),
	}

	if err := action(); err != nil {
		transition.Error = err
		sm.history = append(sm.history, transition)
		sm.current = StateError
		return fmt.Errorf("transition %s -> %s failed: %w", from, to, err)
	}

	sm.current = to
	sm.history = append(sm.history, transition)

	// Execute enter hook
	if enterFn, ok := sm.onEnter[to]; ok {
		enterFn()
	}

	return nil
}

func (sm *StateMachine) Current() State {
	sm.mu.RLock()
	defer sm.mu.RUnlock()
	return sm.current
}

func (sm *StateMachine) History() []StateTransition {
	sm.mu.RLock()
	defer sm.mu.RUnlock()
	history := make([]StateTransition, len(sm.history))
	copy(history, sm.history)
	return history
}

// ---------------------------------------------------------------------------
// Section 40: Observer pattern
// ---------------------------------------------------------------------------

type EventType string

const (
	EventCreated EventType = "created"
	EventUpdated EventType = "updated"
	EventDeleted EventType = "deleted"
	EventError   EventType = "error"
)

type EventData struct {
	Type      EventType
	Source    string
	Payload   interface{}
	Timestamp time.Time
}

type EventListener func(EventData)

type EventEmitter struct {
	mu        sync.RWMutex
	listeners map[EventType][]EventListener
	all       []EventListener
}

func NewEventEmitter() *EventEmitter {
	return &EventEmitter{
		listeners: make(map[EventType][]EventListener),
	}
}

func (ee *EventEmitter) On(eventType EventType, listener EventListener) {
	ee.mu.Lock()
	defer ee.mu.Unlock()
	ee.listeners[eventType] = append(ee.listeners[eventType], listener)
}

func (ee *EventEmitter) OnAll(listener EventListener) {
	ee.mu.Lock()
	defer ee.mu.Unlock()
	ee.all = append(ee.all, listener)
}

func (ee *EventEmitter) Emit(event EventData) {
	ee.mu.RLock()
	defer ee.mu.RUnlock()

	event.Timestamp = time.Now()

	// Notify specific listeners
	if listeners, ok := ee.listeners[event.Type]; ok {
		for _, listener := range listeners {
			go listener(event)
		}
	}

	// Notify catch-all listeners
	for _, listener := range ee.all {
		go listener(event)
	}
}

// ---------------------------------------------------------------------------
// Section 41: Miscellaneous patterns and edge cases
// ---------------------------------------------------------------------------

// Blank import for side effects
// import _ "net/http/pprof"

// Multi-value assignment
func multiAssign() {
	a, b, c := 1, "two", 3.0
	a, b, c = a+1, b+"!", c*2

	// Swap
	x, y := 10, 20
	x, y = y, x

	// Map lookup with ok
	m := map[string]int{"a": 1}
	v, ok := m["a"]
	_, _ = v, ok

	// Channel receive with ok
	ch := make(chan int, 1)
	ch <- 42
	val, open := <-ch
	_, _ = val, open

	// Type assertion with ok
	var i interface{} = "hello"
	s, ok := i.(string)
	_, _ = s, ok

	_ = a
	_ = b
	_ = c
}

// Blank identifier uses
func blankIdentifier() {
	// Ignore values
	for _, v := range []int{1, 2, 3} {
		_ = v
	}

	// Ignore return values
	_ = add(1, 2)

	// Ignore error (bad practice, but valid syntax)
	f, _ := os.Open("/dev/null")
	if f != nil {
		f.Close()
	}
}

// Composite literals
func compositeLiterals() {
	// Slice literal
	nums := []int{1, 2, 3, 4, 5}

	// Slice of structs
	points := []Point{
		{X: 1, Y: 2},
		{X: 3, Y: 4},
		{5, 6},
	}

	// Map literal
	scores := map[string]int{
		"alice": 100,
		"bob":   95,
		"carol": 88,
	}

	// Nested map
	nested := map[string]map[string]int{
		"group1": {"a": 1, "b": 2},
		"group2": {"c": 3, "d": 4},
	}

	// Slice of maps
	records := []map[string]interface{}{
		{"id": 1, "name": "first", "active": true},
		{"id": 2, "name": "second", "active": false},
	}

	// Array (fixed size)
	arr := [5]int{1, 2, 3, 4, 5}
	autoSize := [...]string{"a", "b", "c"}

	// Struct with pointer
	p := &Point{X: 10, Y: 20}

	_, _, _, _, _, _, _, _ = nums, points, scores, nested, records, arr, autoSize, p
}

// Slice operations
func sliceOperations() {
	s := []int{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}

	// Slicing
	a := s[2:5]   // [2, 3, 4]
	b := s[:3]    // [0, 1, 2]
	c := s[7:]    // [7, 8, 9]
	d := s[:]     // full copy
	e := s[1:5:5] // three-index slice (sets capacity)

	// Append
	s = append(s, 10, 11, 12)
	s = append(s, []int{13, 14, 15}...)

	// Copy
	dst := make([]int, 5)
	n := copy(dst, s)

	// Delete element (preserving order)
	idx := 3
	s = append(s[:idx], s[idx+1:]...)

	// Delete element (not preserving order)
	s[idx] = s[len(s)-1]
	s = s[:len(s)-1]

	// Insert
	insert := 99
	s = append(s[:idx+1], s[idx:]...)
	s[idx] = insert

	_, _, _, _, _, _ = a, b, c, d, e, n
}

// Map operations
func mapOperations() {
	m := make(map[string][]int)

	// Add to map of slices
	m["key1"] = append(m["key1"], 1, 2, 3)
	m["key2"] = append(m["key2"], 4, 5, 6)

	// Check existence
	if vals, ok := m["key1"]; ok {
		fmt.Println("found:", vals)
	}

	// Delete
	delete(m, "key1")

	// Iterate (order is random)
	for k, v := range m {
		fmt.Printf("%s: %v\n", k, v)
	}

	// Get sorted keys
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	// Map with struct values
	type entry struct {
		count int
		last  time.Time
	}
	tracker := make(map[string]*entry)
	tracker["a"] = &entry{count: 1, last: time.Now()}
	tracker["a"].count++
}

// Channel patterns
func channelPatterns() {
	// Nil channel (blocks forever)
	var nilCh chan int
	_ = nilCh

	// Closed channel (returns zero value immediately)
	closed := make(chan int)
	close(closed)
	v, ok := <-closed
	_, _ = v, ok

	// Directional channels
	bidirectional := make(chan int)
	var sendOnly chan<- int = bidirectional
	var recvOnly <-chan int = bidirectional
	_, _ = sendOnly, recvOnly

	// Buffered channel as semaphore
	sem := make(chan struct{}, 3)
	sem <- struct{}{}
	<-sem

	// Channel of channels
	chOfCh := make(chan chan int)
	go func() {
		innerCh := make(chan int, 1)
		innerCh <- 42
		chOfCh <- innerCh
	}()
	inner := <-chOfCh
	fmt.Println(<-inner)

	// Done channel pattern
	done := make(chan struct{})
	go func() {
		defer close(done)
		// work
	}()
	<-done

	// Or-done pattern
	orDone := func(done <-chan struct{}, c <-chan int) <-chan int {
		valStream := make(chan int)
		go func() {
			defer close(valStream)
			for {
				select {
				case <-done:
					return
				case v, ok := <-c:
					if !ok {
						return
					}
					select {
					case valStream <- v:
					case <-done:
					}
				}
			}
		}()
		return valStream
	}
	_ = orDone
}

// Interface embedding and composition patterns
type Validator interface {
	Validate() error
}

type Serializable interface {
	Marshal() ([]byte, error)
	Unmarshal([]byte) error
}

type Entity interface {
	Validator
	Serializable
	fmt.Stringer
	ID() string
	CreatedAt() time.Time
}

// Implement Entity for a concrete type
type Product struct {
	ProductID   string
	ProductName string
	Price       float64
	Created     time.Time
}

func (p Product) Validate() error {
	if p.ProductID == "" {
		return errors.New("product id required")
	}
	if p.ProductName == "" {
		return errors.New("product name required")
	}
	if p.Price < 0 {
		return errors.New("price must be non-negative")
	}
	return nil
}

func (p Product) Marshal() ([]byte, error) {
	return json.Marshal(p)
}

func (p *Product) Unmarshal(data []byte) error {
	return json.Unmarshal(data, p)
}

func (p Product) String() string {
	return fmt.Sprintf("%s: %s ($%.2f)", p.ProductID, p.ProductName, p.Price)
}

func (p Product) ID() string {
	return p.ProductID
}

func (p Product) CreatedAt() time.Time {
	return p.Created
}

// ---------------------------------------------------------------------------
// Section 42: Complex nested scopes for Treesitter depth testing
// ---------------------------------------------------------------------------

func deeplyNestedScopes(ctx context.Context, data [][]map[string]interface{}) error {
	for i, outer := range data {
		if len(outer) == 0 {
			continue
		}
		for j, inner := range outer {
			if inner == nil {
				continue
			}
			for key, value := range inner {
				if key == "" {
					continue
				}
				switch v := value.(type) {
				case map[string]interface{}:
					for innerKey, innerVal := range v {
						if str, ok := innerVal.(string); ok {
							if strings.HasPrefix(str, "special_") {
								parts := strings.Split(str, "_")
								if len(parts) > 2 {
									for _, part := range parts[1:] {
										if len(part) > 3 {
											select {
											case <-ctx.Done():
												return fmt.Errorf("cancelled at [%d][%d][%s][%s]", i, j, key, innerKey)
											default:
												processDeepValue(part)
											}
										}
									}
								}
							}
						}
					}
				case []interface{}:
					for idx, elem := range v {
						if m, ok := elem.(map[string]interface{}); ok {
							for mk, mv := range m {
								result, err := processMapValue(ctx, mk, mv)
								if err != nil {
									if errors.Is(err, context.Canceled) {
										return err
									}
									logMessage("warn", fmt.Sprintf("error at [%d][%d][%s][%d][%s]: %v", i, j, key, idx, mk, err))
									continue
								}
								_ = result
							}
						}
					}
				}
			}
		}
	}
	return nil
}

func processDeepValue(s string) {
	fmt.Println("processing:", s)
}

func processMapValue(ctx context.Context, key string, value interface{}) (string, error) {
	return fmt.Sprintf("%s=%v", key, value), nil
}

// ---------------------------------------------------------------------------
// Section 43: More interface implementations and duck typing
// ---------------------------------------------------------------------------

// io.Reader implementation
type InfiniteReader struct {
	value byte
}

func (r *InfiniteReader) Read(p []byte) (n int, err error) {
	for i := range p {
		p[i] = r.value
	}
	return len(p), nil
}

// io.Writer implementation
type CountingWriter struct {
	Writer    io.Writer
	ByteCount int64
}

func (w *CountingWriter) Write(p []byte) (n int, err error) {
	n, err = w.Writer.Write(p)
	w.ByteCount += int64(n)
	return
}

// io.ReadWriter from composition
type ReadWriter struct {
	reader io.Reader
	writer io.Writer
}

func (rw *ReadWriter) Read(p []byte) (n int, err error) {
	return rw.reader.Read(p)
}

func (rw *ReadWriter) Write(p []byte) (n int, err error) {
	return rw.writer.Write(p)
}

// http.Handler implementation
type APIHandler struct {
	routes map[string]http.HandlerFunc
	prefix string
}

func (h *APIHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, h.prefix)
	key := r.Method + " " + path

	if handler, ok := h.routes[key]; ok {
		handler(w, r)
		return
	}

	http.NotFound(w, r)
}

// error interface implementation
type ValidationError struct {
	Field   string
	Value   interface{}
	Message string
}

func (e *ValidationError) Error() string {
	return fmt.Sprintf("validation error on field %q (value: %v): %s", e.Field, e.Value, e.Message)
}

// sort.Interface implementation
type Tasks []*Task

func (t Tasks) Len() int           { return len(t) }
func (t Tasks) Less(i, j int) bool { return t[i].Priority > t[j].Priority }
func (t Tasks) Swap(i, j int)      { t[i], t[j] = t[j], t[i] }

// encoding.TextMarshaler / TextUnmarshaler
func (s Status) MarshalText() ([]byte, error) {
	switch s {
	case StatusPending:
		return []byte("pending"), nil
	case StatusActive:
		return []byte("active"), nil
	case StatusSuspended:
		return []byte("suspended"), nil
	case StatusClosed:
		return []byte("closed"), nil
	case StatusArchived:
		return []byte("archived"), nil
	default:
		return nil, fmt.Errorf("unknown status: %d", s)
	}
}

func (s *Status) UnmarshalText(text []byte) error {
	switch string(text) {
	case "pending":
		*s = StatusPending
	case "active":
		*s = StatusActive
	case "suspended":
		*s = StatusSuspended
	case "closed":
		*s = StatusClosed
	case "archived":
		*s = StatusArchived
	default:
		return fmt.Errorf("unknown status: %s", text)
	}
	return nil
}

// ---------------------------------------------------------------------------
// Section 44: Functional options pattern
// ---------------------------------------------------------------------------

type ClientOption func(*Client)

type Client struct {
	baseURL    string
	httpClient *http.Client
	timeout    time.Duration
	retries    int
	headers    http.Header
	logger     *log.Logger
	rateLimit  float64
	debug      bool
	userAgent  string
	onError    func(error)
	onRequest  func(*http.Request)
	onResponse func(*http.Response)
}

func WithTimeout(d time.Duration) ClientOption {
	return func(c *Client) {
		c.timeout = d
		c.httpClient.Timeout = d
	}
}

func WithRetries(n int) ClientOption {
	return func(c *Client) {
		c.retries = n
	}
}

func WithHeader(key, value string) ClientOption {
	return func(c *Client) {
		c.headers.Set(key, value)
	}
}

func WithLogger(l *log.Logger) ClientOption {
	return func(c *Client) {
		c.logger = l
	}
}

func WithRateLimit(rps float64) ClientOption {
	return func(c *Client) {
		c.rateLimit = rps
	}
}

func WithDebug(enabled bool) ClientOption {
	return func(c *Client) {
		c.debug = enabled
	}
}

func WithUserAgent(ua string) ClientOption {
	return func(c *Client) {
		c.userAgent = ua
	}
}

func WithOnError(fn func(error)) ClientOption {
	return func(c *Client) {
		c.onError = fn
	}
}

func NewClient(baseURL string, opts ...ClientOption) *Client {
	c := &Client{
		baseURL:    baseURL,
		httpClient: &http.Client{Timeout: 30 * time.Second},
		timeout:    30 * time.Second,
		retries:    3,
		headers:    make(http.Header),
		userAgent:  UserAgent,
	}

	for _, opt := range opts {
		opt(c)
	}

	return c
}

func (c *Client) Do(ctx context.Context, method, path string, body io.Reader) (*http.Response, error) {
	url := c.baseURL + path

	var lastErr error
	for attempt := 0; attempt <= c.retries; attempt++ {
		if attempt > 0 {
			select {
			case <-ctx.Done():
				return nil, ctx.Err()
			case <-time.After(time.Duration(attempt) * time.Second):
			}
		}

		req, err := http.NewRequestWithContext(ctx, method, url, body)
		if err != nil {
			return nil, fmt.Errorf("create request: %w", err)
		}

		// Set headers
		for key, values := range c.headers {
			for _, v := range values {
				req.Header.Add(key, v)
			}
		}
		req.Header.Set("User-Agent", c.userAgent)

		if c.onRequest != nil {
			c.onRequest(req)
		}

		if c.debug && c.logger != nil {
			c.logger.Printf("-> %s %s", method, url)
		}

		resp, err := c.httpClient.Do(req)
		if err != nil {
			lastErr = err
			if c.onError != nil {
				c.onError(err)
			}
			continue
		}

		if c.onResponse != nil {
			c.onResponse(resp)
		}

		if c.debug && c.logger != nil {
			c.logger.Printf("<- %d %s", resp.StatusCode, resp.Status)
		}

		// Retry on 5xx
		if resp.StatusCode >= 500 && attempt < c.retries {
			resp.Body.Close()
			lastErr = fmt.Errorf("server error: %d", resp.StatusCode)
			continue
		}

		return resp, nil
	}

	return nil, fmt.Errorf("all %d retries failed: %w", c.retries, lastErr)
}

// ---------------------------------------------------------------------------
// Section 45: Additional constructs for completeness
// ---------------------------------------------------------------------------

// Nested function calls and method chains
func demonstrateChaining() {
	query, params := NewQueryBuilder("users").
		Select("id", "name", "email").
		Join("orders", "orders.user_id = users.id").
		Where("users.active =", true).
		Where("orders.total >", 100).
		OrderBy("users.name", "ASC").
		Limit(10).
		Offset(0).
		Build()
	fmt.Println(query, params)
}

// Multi-return with named types
type Coordinates struct {
	Lat, Lng float64
}

func parseCoordinates(s string) (coords Coordinates, valid bool) {
	parts := strings.Split(s, ",")
	if len(parts) != 2 {
		return
	}
	lat, err := strconv.ParseFloat(strings.TrimSpace(parts[0]), 64)
	if err != nil {
		return
	}
	lng, err := strconv.ParseFloat(strings.TrimSpace(parts[1]), 64)
	if err != nil {
		return
	}
	return Coordinates{Lat: lat, Lng: lng}, true
}

// Sentinel values
var (
	sentinel1 = struct{}{}
	sentinel2 = (*int)(nil)
	sentinel3 = errors.New("sentinel")
)

// Package-level function variables
var (
	marshalFn   = json.Marshal
	unmarshalFn = json.Unmarshal
	printFn     = fmt.Printf
)

// Ensure interface compliance at compile time
var (
	_ Entity         = (*Product)(nil)
	_ io.Reader      = (*InfiniteReader)(nil)
	_ io.Writer      = (*CountingWriter)(nil)
	_ error          = (*AppError)(nil)
	_ error          = (*ValidationError)(nil)
	_ error          = (*MultiError)(nil)
	_ http.Handler   = (*APIHandler)(nil)
	_ sort.Interface = (Tasks)(nil)
	_ sort.Interface = (ByName)(nil)
)

// Type aliases vs type definitions
type (
	Bytes      = []byte                    // alias — same type as []byte
	JSON       = map[string]interface{}    // alias
	HandlerMap map[string]http.HandlerFunc // new type
	ErrorList  []error                     // new type
)

// Complex constant expressions
const (
	KB = 1024
	MB = 1024 * KB
	GB = 1024 * MB
	TB = 1024 * GB

	MaxFileSize = 100 * MB
	MaxBodySize = 10 * MB
)

// Stringer via fmt.GoStringer
func (p Point) GoString() string {
	return fmt.Sprintf("Point{X: %g, Y: %g}", p.X, p.Y)
}

// net.Listener interface stub (for compilation)
type (
	net         struct{}
	netListener interface {
		Accept() (netConn, error)
		Close() error
		Addr() netAddr
	}
)
type netConn interface {
	io.ReadWriteCloser
	LocalAddr() netAddr
	RemoteAddr() netAddr
	SetDeadline(t time.Time) error
}
type netAddr interface {
	Network() string
	String() string
}

// Ensure the file reaches the target line count with a comprehensive
// usage function that exercises many of the above constructs
func exerciseAllConstructs() {
	// Points
	p1 := Point{X: 3, Y: 4}
	p2 := Point{X: 6, Y: 8}
	fmt.Println(p1.Distance(p2))
	p1.Translate(1, 1)
	p1.Scale(2)
	fmt.Println(p1)

	// Config
	cfg := defaultConfig
	cfg.ApplyDefaults()
	if err := cfg.Validate(); err != nil {
		fmt.Println("config error:", err)
	}

	// Generic data structures
	ll := &LinkedList[string]{}
	ll.Append("hello")
	ll.Append("world")
	ll.ForEach(func(s string) { fmt.Println(s) })

	stack := &Stack[int]{}
	stack.Push(1)
	stack.Push(2)
	stack.Push(3)
	for !stack.IsEmpty() {
		v, _ := stack.Pop()
		fmt.Println(v)
	}

	bst := &BinarySearchTree[int]{}
	for _, v := range []int{5, 3, 7, 1, 4, 6, 8} {
		bst.Insert(v)
	}
	fmt.Println("in order:", bst.InOrder())
	fmt.Println("search 4:", bst.Search(4))

	// Generic functions
	doubled := Map([]int{1, 2, 3}, func(x int) int { return x * 2 })
	fmt.Println("doubled:", doubled)

	hasThree := Contains([]int{1, 2, 3, 4}, 3)
	fmt.Println("has three:", hasThree)

	minimum := Min(42, 17)
	fmt.Println("min:", minimum)

	groups := GroupBy([]string{"apple", "avocado", "banana", "blueberry"}, func(s string) byte { return s[0] })
	fmt.Println("groups:", groups)

	// Option type
	some := Some(42)
	none := None[int]()
	fmt.Println(some.Unwrap())
	fmt.Println(none.UnwrapOr(0))
	mapped := some.Map(func(x int) int { return x * 2 })
	fmt.Println(mapped.Unwrap())

	// Result type
	r := NewResult("success", nil)
	if !r.IsError() {
		v, _ := r.Unwrap()
		fmt.Println(v)
	}

	// Ordered map
	om := &OrderedMap[string, int]{}
	om.Set("c", 3)
	om.Set("a", 1)
	om.Set("b", 2)
	fmt.Println("keys:", om.Keys())
	om.Range(func(k string, v int) bool {
		fmt.Printf("%s=%d\n", k, v)
		return true
	})

	// Safe counter
	sc := NewSafeCounter()
	sc.Increment("hits")
	sc.Increment("hits")
	fmt.Println("hits:", sc.Get("hits"))

	// Functional operations
	sum := Reduce([]int{1, 2, 3, 4, 5}, 0, func(acc, v int) int { return acc + v })
	fmt.Println("sum:", sum)

	evens := Filter([]int{1, 2, 3, 4, 5}, func(n int) bool { return n%2 == 0 })
	fmt.Println("evens:", evens)

	chunks := Chunk([]int{1, 2, 3, 4, 5, 6, 7}, 3)
	fmt.Println("chunks:", chunks)

	pairs := Zip([]string{"a", "b", "c"}, []int{1, 2, 3})
	fmt.Println("pairs:", pairs)

	// String slice methods
	ss := StringSlice{"go", "rust", "python", "java"}
	fmt.Println("contains go:", ss.Contains("go"))
	filtered := ss.Filter(func(s string) bool { return len(s) > 3 })
	fmt.Println("filtered:", filtered.Join(", "))

	// Event emitter
	emitter := NewEventEmitter()
	emitter.On(EventCreated, func(e EventData) {
		fmt.Println("created:", e.Payload)
	})
	emitter.Emit(EventData{Type: EventCreated, Source: "test", Payload: "item1"})

	// State machine
	sm := NewStateMachine(StateIdle)
	sm.AddTransition(StateIdle, StateConnecting, func() error {
		fmt.Println("connecting...")
		return nil
	})
	sm.AddTransition(StateConnecting, StateConnected, func() error {
		fmt.Println("connected!")
		return nil
	})
	sm.OnEnter(StateConnected, func() {
		fmt.Println("entered connected state")
	})
	sm.Transition(StateConnecting)
	sm.Transition(StateConnected)

	// Task runner
	runner := NewTaskRunner("test", 4)
	runner.AddTask(&Task{
		ID:       "task-1",
		Name:     "sample",
		Priority: 1,
		Fn: func(ctx context.Context) (interface{}, error) {
			return "done", nil
		},
		Timeout: 5 * time.Second,
	})

	// Client with options
	client := NewClient("https://api.example.com",
		WithTimeout(10*time.Second),
		WithRetries(3),
		WithHeader("X-API-Key", "secret"),
		WithDebug(true),
		WithUserAgent("test-client/1.0"),
	)
	_ = client

	// Demonstrating various control flows
	demonstrateIfElse(42)
	demonstrateIfWithInit()
	demonstrateForLoops()
	demonstrateSwitch(5)
	demonstrateTypeSwitch("hello")
	isNumeric(42)
	demonstrateClosures()
	demonstrateDefer()
	multiAssign()
	blankIdentifier()
	compositeLiterals()
	sliceOperations()
	mapOperations()
	channelPatterns()
	demonstrateStrings()
	demonstrateRegex()
	demonstrateJSON()
	demonstrateChaining()
	demonstrateReflection()

	// Query builder
	query, params := NewQueryBuilder("products").
		Select("p.id", "p.name", "p.price", "c.name AS category").
		Join("categories c", "c.id = p.category_id").
		LeftJoin("reviews r", "r.product_id = p.id").
		Where("p.price >", 10.00).
		Where("p.active =", true).
		GroupBy("p.id", "p.name", "p.price", "c.name").
		Having("COUNT(r.id) > 0").
		OrderBy("p.price", "DESC").
		Limit(20).
		Build()
	fmt.Println(query, params)

	// Product entity
	product := Product{
		ProductID:   "prod-1",
		ProductName: "Widget",
		Price:       29.99,
		Created:     time.Now(),
	}
	if err := product.Validate(); err != nil {
		fmt.Println("invalid:", err)
	}
	data, _ := product.Marshal()
	fmt.Println(string(data))
	fmt.Println(product.String())

	// Error handling
	demonstrateErrorHandling()

	// Complex function
	results, count, err := complexFunction(
		context.Background(),
		[]interface{}{"a", 1, 3.14, nil, true},
		map[string]interface{}{"verbose": true},
		func(s string) error {
			fmt.Println("callback:", s)
			return nil
		},
	)
	fmt.Println(results, count, err)
}
