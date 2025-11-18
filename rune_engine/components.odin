package rune_engine

import "rendering"

import jph "deps/joltc-odin/"

TransformComponent :: struct {
	position: [3]f32,
	rotation: quaternion128,
	scale:    [3]f32,
}

CameraComponent :: struct {
	fov:       f32,
	aspect:    f32,
	near, far: f32,
}

MeshRendererComponent :: struct {
	mesh: rendering.Mesh,
}

BodyType :: enum {
	Static,
	Dynamic,
	Kinematic,
}

RigidBodyComponent :: struct {
	type:       BodyType,
	is_trigger: bool,
	shape:      PhysicsShape,
	body_id:    jph.BodyID,
}

PhysicsShape :: union {
	BoxShape,
	SphereShape,
	CapsuleShape,
	PlaneShape,
	TriangleShape,
	MeshShape,
	ConvexHullShape,
}

BoxShape :: struct {
	offset:  [3]f32,
	extents: [3]f32,
}

SphereShape :: struct {
	offset: [3]f32,
	radius: f32,
}

CapsuleShape :: struct {
	offset: [3]f32,
	height: f32,
	radius: f32,
}

PlaneShape :: struct {
	offset: [3]f32,
	normal: [3]f32,
}

TriangleShape :: struct {
	a, b, c: [3]f32,
}

MeshShape :: struct {
	triangles: []jph.Triangle,
}

ConvexHullShape :: struct {
	points: [][3]f32,
}
