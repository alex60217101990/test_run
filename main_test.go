package main_test

import (
	"math"
	"testing"

	"github.com/leanovate/gopter"
	"github.com/leanovate/gopter/gen"
	"github.com/leanovate/gopter/prop"
)

type Compute struct {
	A uint32
	B uint32
}

func (c *Compute) CoerceInt()      { c.A = c.A % 10; c.B = c.B % 10 }
func (c Compute) Add() uint32      { return c.A + c.B }
func (c Compute) Subtract() uint32 { return c.A - c.B }
func (c Compute) Divide() uint32   { return c.A / c.B }
func (c Compute) Multiply() uint32 { return c.A * c.B }

func TestCompute(t *testing.T) {
	parameters := gopter.DefaultTestParameters()
	parameters.Rng.Seed(1234) // Just for this example to generate reproducible results

	properties := gopter.NewProperties(parameters)

	properties.Property("Add should never fail.", prop.ForAll(
		func(a uint32, b uint32) bool {
			inpCompute := Compute{A: a, B: b}
			inpCompute.CoerceInt()
			inpCompute.Add()
			return true
		},
		gen.UInt32Range(0, math.MaxUint32),
		gen.UInt32Range(0, math.MaxUint32),
	))

	properties.Property("Subtract should never fail.", prop.ForAll(
		func(a uint32, b uint32) bool {
			inpCompute := Compute{A: a, B: b}
			inpCompute.CoerceInt()
			inpCompute.Subtract()
			return true
		},
		gen.UInt32Range(0, math.MaxUint32),
		gen.UInt32Range(0, math.MaxUint32),
	))

	properties.Property("Multiply should never fail.", prop.ForAll(
		func(a uint32, b uint32) bool {
			inpCompute := Compute{A: a, B: b}
			inpCompute.CoerceInt()
			inpCompute.Multiply()
			return true
		},
		gen.UInt32Range(0, math.MaxUint32),
		gen.UInt32Range(0, math.MaxUint32),
	))

	properties.Property("Divide should never fail.", prop.ForAll(
		func(a uint32, b uint32) bool {
			inpCompute := Compute{A: a, B: b}
			inpCompute.CoerceInt()
			inpCompute.Divide()
			return true
		},
		gen.UInt32Range(0, math.MaxUint32),
		gen.UInt32Range(0, math.MaxUint32),
	))

	properties.TestingRun(t)
	// ---
}
