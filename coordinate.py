"""Unity <-> glTF coordinate conversion.

Unity is LEFT-handed, +Y up, +Z forward, +X right.
glTF is RIGHT-handed, +Y up, +Z forward -- the asset's front faces +Z, which
makes -X (not +X) the model's right (glTF 2.0 spec, "Coordinate System and
Units").

Both agree on the up axis and on which way the model faces, and differ only in
handedness, so the conversion is the single-axis reflection::

    p_gltf = (-x, y, z)

Negating X keeps the model FACING THE VIEWER -- Painter's default camera then
looks at the character's face rather than the back of its head. Negating Z would
instead land the model in the orientation the material's own
_FaceForward/_FaceRight constants assume, but at the cost of the model facing
away, which is not worth it: the same 180 deg is expressible in the two face-axis
parameters, which is where it now lives. Because a single reflection ``C`` is its own inverse, an
entire transform converts by conjugation::

    M_gltf = C @ M_unity @ C

which carries rotation, translation and handedness across consistently with no
per-quaternion guesswork. Since ``det(C) = -1`` the conversion flips triangle
winding, so faces must have their winding reversed to keep normals outward, and
a tangent's handedness sign (glTF TANGENT.w, where bitangent =
cross(normal, tangent.xyz) * w) must be negated for the same reason.

Pure numpy, so it is testable outside Painter.
"""

from __future__ import annotations

import numpy as np

# 4x4 reflection that negates X (its own inverse).
CONVERSION = np.diag([-1.0, 1.0, 1.0, 1.0]).astype(np.float64)


def convert_matrix(unity_matrix):
    """Conjugate a Unity 4x4 (numpy array) into glTF space."""
    return CONVERSION @ np.asarray(unity_matrix, dtype=np.float64) @ CONVERSION


def unity_trs(position, rotation, scale):
    """Build a Unity-space TRS matrix from dict components {x,y,z[,w]}."""
    x = float(rotation.get("x", 0.0))
    y = float(rotation.get("y", 0.0))
    z = float(rotation.get("z", 0.0))
    w = float(rotation.get("w", 1.0))
    norm = (x * x + y * y + z * z + w * w) ** 0.5
    if norm > 1e-12:
        x, y, z, w = x / norm, y / norm, z / norm, w / norm
    else:
        x, y, z, w = 0.0, 0.0, 0.0, 1.0

    rot = np.array([
        [1.0 - 2.0 * (y * y + z * z), 2.0 * (x * y - z * w), 2.0 * (x * z + y * w)],
        [2.0 * (x * y + z * w), 1.0 - 2.0 * (x * x + z * z), 2.0 * (y * z - x * w)],
        [2.0 * (x * z - y * w), 2.0 * (y * z + x * w), 1.0 - 2.0 * (x * x + y * y)],
    ], dtype=np.float64)

    scl = np.array([float(scale.get("x", 1.0)),
                    float(scale.get("y", 1.0)),
                    float(scale.get("z", 1.0))], dtype=np.float64)

    matrix = np.eye(4, dtype=np.float64)
    matrix[:3, :3] = rot * scl[None, :]   # R @ diag(S)
    matrix[0, 3] = float(position.get("x", 0.0))
    matrix[1, 3] = float(position.get("y", 0.0))
    matrix[2, 3] = float(position.get("z", 0.0))
    return matrix


def convert_points(points):
    """Convert an (n, 3) array of Unity positions/normals to glTF space.

    The negated axis must be the same one CONVERSION uses, or directions and
    geometry end up in different spaces."""
    out = np.asarray(points, dtype=np.float32).copy()
    out[:, 0] *= -1.0
    return out


def convert_tangents(tangents):
    """Convert an (n, 4) Unity tangent array (xyz + handedness sign) to glTF.

    The tangent itself is just dP/du and u is untouched, so it converts like any
    other direction: negate the same axis as CONVERSION. The handedness sign w
    (glTF: bitangent = cross(normal, tangent.xyz) * w) is where it gets subtle,
    because TWO of the three conversion steps act on it and they cancel:

      * the reflection flips the sign of every cross product   -> w would flip;
      * the V flip reverses dP/dv, i.e. the bitangent itself    -> w flips back.

    Working it through: cross(N', T') = -C cross(N, T) = -w * C B = w * B'
    (since B' = -C B), and glTF wants B' = cross(N', T') * w', so w' = w.
    Negating w here -- correct for a reflection ALONE -- would invert every
    bitangent now that convert_uvs is part of the conversion.
    """
    out = np.asarray(tangents, dtype=np.float32).copy()
    out[:, 0] *= -1.0
    return out


def reverse_winding(triangles):
    """Reverse triangle winding to compensate for the reflection."""
    return np.asarray(triangles)[:, (0, 2, 1)]


def convert_uvs(uvs):
    """Unity UV -> glTF UV: flip V.

    This is a third piece of the same conversion, not a preference. The two
    formats disagree on where the texture origin is: Unity puts (0, 0) at the
    BOTTOM-left of the image, glTF at the TOP-left ("The origin of the UV
    coordinates (0, 0) corresponds to the upper left corner of a texture
    image", glTF 2.0 3.7.5). Writing Unity's V through unchanged therefore
    mirrors every texture vertically on the model.

    Note this is exactly why the Blender importer has no equivalent step:
    Blender's UV origin is bottom-left, the same as Unity's, so that path is a
    straight copy. Do not conflate the two.
    """
    out = np.asarray(uvs, dtype=np.float32).copy()
    out[:, 1] = 1.0 - out[:, 1]
    return out


def transform_points(matrix, points):
    """Apply a 4x4 (glTF-space) matrix to an (n, 3) point array."""
    pts = np.asarray(points, dtype=np.float64)
    homogeneous = np.concatenate([pts, np.ones((len(pts), 1), dtype=np.float64)], axis=1)
    return (homogeneous @ np.asarray(matrix, dtype=np.float64).T)[:, :3].astype(np.float32)


def transform_directions(matrix, vectors):
    """Apply the rotation/scale part of a 4x4 to an (n, 3) direction array and
    renormalise -- for normals carried through a node transform."""
    vecs = np.asarray(vectors, dtype=np.float64)
    out = vecs @ np.asarray(matrix, dtype=np.float64)[:3, :3].T
    lengths = np.linalg.norm(out, axis=1, keepdims=True)
    lengths[lengths < 1e-9] = 1.0
    return (out / lengths).astype(np.float32)
