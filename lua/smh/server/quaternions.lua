local abs = math.abs
local sqrt = math.sqrt
local atan2 = math.atan2
local deg = math.deg
local asin = math.asin
local acos = math.acos
local pi = math.pi
local sin = math.sin
local cos = math.cos
local min = math.min
local max = math.max
local Round = math.Round
local rad = math.rad




local function copysign(a, b)
    return abs(a) * (b >= 0 and 1 or -1)
end


local function adjustAnglex2(angle1, angle2)
    local delta = angle2 - angle1

    if delta > 180 then
        angle2 = angle2 - 360
    elseif delta < -180 then
        angle2 = angle2 + 360
    end

    return angle2
end



--local MGR = {}

function SMH.Quaternion(w, x, y, z)
    return { w = w, x = x, y = y, z = z }
end


function SMH.QuaternionDot(q1, q2)
    return q1.w * q2.w + q1.x * q2.x + q1.y * q2.y + q1.z * q2.z
end


function SMH.QuaternionInverter(q)
    --q = { w = -q.w, x = -q.x, y = -q.y, z = -q.z }
    q = { w = -q.w, x = -q.x, y = -q.y, z = -q.z }
    return q
end


function SMH.quaternion_inverse(q)
    local w, x, y, z = q.w, q.x, q.y, q.z
    local norm_squared = w*w + x*x + y*y + z*z
    --return {w / norm_squared, -x / norm_squared, -y / norm_squared, -z / norm_squared}
    return {
        w = w/norm_squared,
        x = -x/norm_squared,
        y = -y/norm_squared,
        z = -z/norm_squared
    }
end


function SMH.QuaternionNormalize(q)
    local norm = sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w)
    if norm == 0 then return q end
    return SMH.Quaternion(q.w / norm, q.x / norm, q.y / norm, q.z / norm)
end


function SMH.QuaternionTangentLimit(quaternion, maxLength)
    -- Calcula la longitud (magnitud) del cuaternión
    local length = sqrt(quaternion.x^2 + quaternion.y^2 + quaternion.z^2 + quaternion.w^2)

    -- Si la longitud es mayor que el valor máximo, normaliza el cuaternión
    --print("Q LENGTH", length)
    if length > maxLength then
        local scale = maxLength / length
        quaternion.x = quaternion.x * scale
        quaternion.y = quaternion.y * scale
        quaternion.z = quaternion.z * scale
        quaternion.w = quaternion.w * scale
    end
    
    return quaternion
end


function SMH.QuaternionToAngle(q)
    -- Roll (z-axis rotation)
    local sinr_cosp = 2 * (q.w * q.x + q.y * q.z)
    local cosr_cosp = 1 - 2 * (q.x * q.x + q.y * q.y)
    local roll = deg(atan2(sinr_cosp, cosr_cosp))

    -- Pitch (x-axis rotation)
    local sinp = 2 * (q.w * q.y - q.z * q.x)
    local pitch
    if abs(sinp) >= 1 then
        pitch = deg(copysign(pi / 2, sinp)) -- use 90 degrees if out of range
    else
        pitch = deg(asin(sinp))
    end

    -- Yaw (y-axis rotation)
    local siny_cosp = 2 * (q.w * q.z + q.x * q.y)
    local cosy_cosp = 1 - 2 * (q.y * q.y + q.z * q.z)
    local yaw = deg(atan2(siny_cosp, cosy_cosp))


    return Angle(pitch, yaw, roll)
end


function SMH.AngleToQuaternion(angle)
  
    local cy = cos(rad(angle.yaw) * 0.5)
    local sy = sin(rad(angle.yaw) * 0.5)
    local cp = cos(rad(angle.pitch) * 0.5)
    local sp = sin(rad(angle.pitch) * 0.5)
    local cr = cos(rad(angle.roll) * 0.5)
    local sr = sin(rad(angle.roll) * 0.5)

    local w = cr * cp * cy + sr * sp * sy
    local x = sr * cp * cy - cr * sp * sy
    local y = cr * sp * cy + sr * cp * sy
    local z = cr * cp * sy - sr * sp * cy

    return SMH.Quaternion(w, x, y, z)
end


function SMH.AdjustQuaternionOrientation(q1, q2)
    if SMH.QuaternionDot(q1, q2) < 0 then
        q2 = SMH.QuaternionInverter(q2)
    end
    return q2
end


function SMH.QuaternionScale(q, s)
    return {
        w = q.w * s,
        x = q.x * s,
        y = q.y * s,
        z = q.z * s
    }
end


function SMH.QuaternionMultiply(q1, q2)
    return {
        w = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z,
        x = q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y,
        y = q1.w * q2.y - q1.x * q2.z + q1.y * q2.w + q1.z * q2.x,
        z = q1.w * q2.z + q1.x * q2.y - q1.y * q2.x + q1.z * q2.w
    }
end


function SMH.QuaternionAdd(q1, q2)
    return {
        w = q1.w + q2.w,
        x = q1.x + q2.x,
        y = q1.y + q2.y,
        z = q1.z + q2.z
    }
end


function SMH.quaternion_log(q)
    local w, x, y, z = q.w, q.x, q.y, q.z
    local angle = acos(w)
  
    if angle == 0 then
      return {0, 0, 0, 0}
    else
      local s = sin(angle)
      return {
        w = w,
        x =  x / s * angle,
        y = y / s * angle,
        z = z / s * angle
      }
    end
end


function SMH.QuaternionAngleDelta(q1, q2)
    -- Calcular el producto escalar entre q0 y q1
    local dot = SMH.QuaternionDot(q1, q2)
    -- Limitar el valor de dot entre [-1, 1] para evitar errores numéricos
    dot = max(-1, min(1, dot))
    -- Calcular la diferencia angular en radianes
    local angleDifference = acos(dot) * 2
    
    return angleDifference 
end

function SMH.QuaternionAreEqual(q1, q2, tolerance)
    tolerance = tolerance or 1e-6 -- Establece una tolerancia por defecto si no se proporciona.
    return math.abs(q1.w - q2.w) < tolerance and
           math.abs(q1.x - q2.x) < tolerance and
           math.abs(q1.y - q2.y) < tolerance and
           math.abs(q1.z - q2.z) < tolerance
end


function SMH.quattest(q)
    local qfinal = (q.w + q.x + q.y + q.z)
    return Round(qfinal, 4)
end


function SMH.quatinv(q)
    return {
        w = -q.w,
        x = -q.x,
        y = -q.y,
        z = -q.z
    }
end


function SMH.quatmult(q1, q2)
    if type(q2) == "number" then
        return {
            w = q1.w * q2,
            x = q1.x * q2,
            y = q1.y * q2,
            z = q1.z * q2
        }
    else
        return {
            w = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z,
            x = q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y,
            y = q1.w * q2.y - q1.x * q2.z + q1.y * q2.w + q1.z * q2.x,
            z = q1.w * q2.z + q1.x * q2.y - q1.y * q2.x + q1.z * q2.w
        }
    end
end


function SMH.quatequal(q1, q2)
    return q1.w == q2.w and q1.x == q2.x and q1.y == q2.y and q1.z == q2.z
end
