
local linealSwitch = false
local resultAngle = angle_zero
local currentFrame = 0

local abs = math.abs
local min = math.min
local max = math.max



local function QuaternionHermiteInterpolate(t, q0, q1, m0, m1)

    local dot = SMH.QuaternionDot(q0, q1)

    if dot < 0.0 then
        q1 = SMH.QuaternionInverter(q1)
    end

    local t2 = t * t
    local t3 = t2 * t

    -- Hermite interpolation
    local h1 = 2*t3 - 3*t2 + 1
    local h2 = t3 - 2 * t2 + t
    local h3 = -2 * t3 + 3 * t2
    local h4 = t3 - t2

    local interpolatedQuat = {
        w = h1 * q0.w + h2 * m0.w + h3 * q1.w + h4 * m1.w,
        x = h1 * q0.x + h2 * m0.x + h3 * q1.x + h4 * m1.x,
        y = h1 * q0.y + h2 * m0.y + h3 * q1.y + h4 * m1.y,
        z = h1 * q0.z + h2 * m0.z + h3 * q1.z + h4 * m1.z
    }
    

    interpolatedQuat = SMH.QuaternionNormalize(interpolatedQuat)

    return interpolatedQuat
end


local function QuaternionCalculateTangents(q_prev, q_current, q_next, q_next2, ts)

    local dt1 = ts[3] - ts[1] 
    local dt2 = ts[4] - ts[2]  

    local weight0 = dt1 / (dt1 + dt2) 
    local weight1 = dt2 / (dt1 + dt2) 

    
    if SMH.QuaternionDot(q_prev, q_next) < 0 then
        q_prev = SMH.quatinv(q_prev) -- Invertir el cuaternión para seguir el camino más corto 
    end 
    if SMH.QuaternionDot(q_current, q_next2) < 0 then
        q_current = SMH.quatinv(q_current) -- Invertir el cuaternión para seguir el camino más corto
    end

    --weight conditions
    if SMH.QuaternionAreEqual(q_prev, q_current) then
        weight0 = 0
    end
    if SMH.QuaternionAreEqual(q_next, q_next2) then
        weight1 = 0
    end
    if SMH.QuaternionAreEqual(q_current, q_next) and not SMH.QuaternionAreEqual(q_next, q_next2) then
        weight0 = 0
    end
    if SMH.QuaternionAreEqual(q_current, q_next) and not SMH.QuaternionAreEqual(q_prev, q_current) then
        weight1 = 0
    end
    if SMH.QuaternionAreEqual(q_current, q_next, 0.03) then
        weight0 = weight0 * 0.5
        weight1 = weight1 * 0.5
    end


    local qm0 = SMH.Quaternion(
        weight0 * (q_next.w - q_prev.w),
        weight0 * (q_next.x - q_prev.x),
        weight0 * (q_next.y - q_prev.y),
        weight0 * (q_next.z - q_prev.z)
    )
    local qm1 = SMH.Quaternion(
        weight1 * (q_next2.w - q_current.w),
        weight1 * (q_next2.x - q_current.x),
        weight1 * (q_next2.y - q_current.y),
        weight1 * (q_next2.z - q_current.z)
    )


    if SMH.QuaternionDot(q_prev, q_next) < 0 then
        qm0 = SMH.QuaternionInverter(qm0) -- Invertir el cuaternión para seguir el camino más corto 
    end
    
    
    if SMH.QuaternionDot(q_current, q_next2) < 0 then
        qm1 = SMH.QuaternionInverter(qm1) -- Invertir el cuaternión para seguir el camino más corto
    end

    return qm0, qm1 
end



local cachedt0, cachedt1 = 0, 0
local cachedprevf, cachednextf = SMH.Quaternion(0, 0, 0, 0), SMH.Quaternion(0, 0, 0, 0)

local function HermiteEasingQuaternion(t, prev, p1, p2, p3, ts)

    local q_tangent0, q_tangent1

    p2 = SMH.AdjustQuaternionOrientation(p1, p2)
    p3 = SMH.AdjustQuaternionOrientation(p1, p3)


    --if SMH.quatequal(cachedprevf, p1) and SMH.quatequal(cachednextf, p2) then
    if SMH.QuaternionAreEqual(cachedprevf, p1) and SMH.QuaternionAreEqual(cachednextf, p2) then
        q_tangent0 = cachedt0
        q_tangent1 = cachedt1
    else
        q_tangent0, q_tangent1 = QuaternionCalculateTangents(prev, p1, p2, p3, ts) 
    end

    cachedprevf = p1
    cachednextf = p2
    cachedt0 = q_tangent0
    cachedt1 = q_tangent1


    local interpolatedQuat = QuaternionHermiteInterpolate(t, p1, p2, q_tangent0, q_tangent1)

    return SMH.QuaternionToAngle(interpolatedQuat)
end

   
------------------
-- ANGLE EASING --
------------------


local function LinearEasingAngle(frames, points, t)
    local n = #points
    local fn = #frames
    -- Asegúrate de que haya al menos 2 puntos para la interpolación
    if n < 2 then
        table.insert(points, points[1])
    end
    --FRMAES INPLEMENTASHON

    -- Encontrar el segmento adecuado
    local scaledT
    local index
    local localT
    local firstFrame = frames[1]
    local lastFrame = frames[fn]

    --NEWNEWNENWNE
    scaledT = allFrames_actualFrame
    --NEWNEWNWEN


    -- Ajustar el índice para empezar en 0, como en la primera implementación
    index = 0
    for i = 1, fn - 1 do
        if scaledT >= frames[i] and scaledT <= frames[i + 1] then
            index = i  -- Restar 1 para compensar el inicio desde 0
            firstFrame = frames[i]
            lastFrame = frames[i + 1]
            break
        end
    end
    

    if allFrames_actualFrame < frames[1] then
        localT = 0
        index = 0
    elseif allFrames_actualFrame > frames[fn] then
        localT = 1
        index = fn-1
    else
        localT = (allFrames_actualFrame - firstFrame) / (lastFrame - firstFrame)
    end

    localT = max(0, min(1, localT))

    -- Encuentra los puntos que se usarán para la interpolación lineal
    --local idx = math.floor(t * (n - 1)) + 1
    local p1 = SMH.QuaternionToAngle(points[max(1, index)])
    local p2 = SMH.QuaternionToAngle(points[min(n, index + 1)])
    --local localT = (t * (n - 1)) % 1
    local AngleFinal = LerpAngle(localT, p1, p2)
  
    AngleFinal:Normalize()
    return AngleFinal
end


local framestable = {}
local pprev, pp1, pp2, pp3 = nil, nil, nil, nil


local function HermiteEasingAngle(frames, points, t)
    local n = #points
    local fn = #frames

    if n < 2 then
        table.insert(points, points[1])
    end

    local scaledT
    local index
    local localT
    local firstFrame = frames[1]
    local lastFrame = frames[fn]
    

    scaledT = allFrames_actualFrame

    index = 0
    
    for i = 1, fn - 1 do
        if scaledT >= frames[i] and scaledT <= frames[i + 1] then
            index = i  
            firstFrame = frames[i]
            lastFrame = frames[i + 1]
            break
        end
    end

    if allFrames_actualFrame < frames[1] then
        localT = 0
        index = 0
    elseif allFrames_actualFrame > frames[fn] then
        localT = 1
        index = fn-1
    else
        localT = (allFrames_actualFrame - firstFrame) / (lastFrame - firstFrame)
        index = index - 1
    end

    localT = max(0, min(1, localT))

    --FRAMES
    framestable[1] = frames[max(index, 1)]
    framestable[2] = frames[max(index + 1, 1)]
    framestable[3] = frames[min(index + 2, fn)]
    framestable[4] = frames[min(index + 3, fn)]
    --POINTS
    pprev = points[max(index, 1)]
    pp1 = points[max(index + 1, 1)]
    pp2 = points[min(index + 2, n)]
    pp3 = points[min(index + 3, n)]


    result = HermiteEasingQuaternion(localT, pprev, pp1, pp2, pp3, framestable)

    result:Normalize()
    return result
end


function SMH.LerpLinearAngle(s, e, p)

    local resultado

    if SMH.GLOBAL_InterpolationMode == 1 then
        linealSwitch = true
    elseif SMH.GLOBAL_InterpolationMode == 2 then
        linealSwitch = false
    end

    if linealSwitch then
        resultado = LinearEasingAngle(s, e, p)
    else
        resultado = HermiteEasingAngle(s, e, p)
    end   

    return resultado 
end


------------------------------
-- VECTOR and NUMBER EASING --
------------------------------


local function LinearEasingVector(frames, points, t)
    local n = #points
    local fn = #frames
    local scaledT
    local index
    local localT
    local firstFrame = frames[1]
    local lastFrame = frames[fn]
    -- Asegúrate de que haya al menos 2 puntos para la interpolación
    if n < 2 then
        --table.insert(points, points[1])
    end

    scaledT = allFrames_actualFrame

    -- Ajustar el índice para empezar en 0, como en la primera implementación
    index = 0
    for i = 1, fn - 1 do
        if scaledT >= frames[i] and scaledT <= frames[i + 1] then
            index = i  -- Restar 1 para compensar el inicio desde 0
            firstFrame = frames[i]
            lastFrame = frames[i + 1]
            break
        end
    end
    

    if allFrames_actualFrame < frames[1] then
        localT = 0
        index = 0
    elseif allFrames_actualFrame > frames[fn] then
        localT = 1
        index = fn-1
    else
        localT = (allFrames_actualFrame - firstFrame) / (lastFrame - firstFrame)
    end

    localT = max(0, min(1, localT))

    
    local p1 = points[max(1, index)]
    local p2 = points[min(n, index + 1)]

    local VectorFinal = LerpVector(localT, p1, p2);

    return VectorFinal
end


local function LinearEasingNum(frames, points, t)
    local n = #points
    local fn = #frames
    -- Asegúrate de que haya al menos 2 puntos para la interpolación
    if n < 2 then
        table.insert(points, points[1])
    end
    -- Encuentra los puntos que se usarán para la interpolación lineal
    
    --print("allFrames_lastFrame = ", allFrames_lastFrame)

    local scaledT
    local index
    local localT
    local firstFrame = frames[1]
    local lastFrame = frames[fn]

    scaledT = allFrames_actualFrame

    -- Ajustar el índice para empezar en 0, como en la primera implementación
    index = 0
    for i = 1, fn - 1 do
        if scaledT >= frames[i] and scaledT <= frames[i + 1] then
            index = i  -- Restar 1 para compensar el inicio desde 0
            firstFrame = frames[i]
            lastFrame = frames[i + 1]
            break
        end
    end
    
    if allFrames_actualFrame < frames[1] then
        localT = 0
        index = 0
    elseif allFrames_actualFrame > frames[fn] then
        localT = 1
        index = fn-1
    else
        localT = (allFrames_actualFrame - firstFrame) / (lastFrame - firstFrame)
    end

    localT = max(0, min(1, localT))

    local idx = index
    local p1 = points[max(1, idx)]
    local p2 = points[min(n, idx + 1)]

    local NumFinal = Lerp(localT, p1, p2)

    return NumFinal
end


local function AdjustVectorOrientation(v1, v2)
    if type(v1) == "Vector" and type(v2) == "Vector" then
        if v1:Dot(v2) < 0 then
            v2 = v2 * -1  -- Invertir el segundo vector si están en direcciones opuestas
        end
    end
    return v2
end


local function NormalizeTangent(tangent, maxLength)
    local length
    if type(tangent) == "Vector" then
        length = tangent:Length()
        if length > maxLength then
            local scale = maxLength / length
            tangent.x = tangent.x * scale
            tangent.y = tangent.y * scale
            tangent.z = tangent.z * scale
        end
    else
        length = tangent
        if length > maxLength then
            local scale = maxLength / length
            tangent = tangent * scale
        end
    end
    
    return tangent
end


local function HermiteTangentsCalculator(p0, p1, p2, p3, ts)

    local diff = p2 - p0
    local diff2 = p3 - p1
    local p0length = p0
    local p1length = p1
    local p2length = p2
    local p3length = p3

    local dt1 = ts[3] - ts[1]
    local dt2 = ts[4] - ts[2]

    if type(diff) == "Vector" and type(diff2) == "Vector" then
        p0length = p0:Length()
        p1length = p1:Length()
        p2length = p2:Length()
        p3length = p3:Length()
    end
    
    local weight0 = dt1 / (dt1 + dt2)
    local weight1 = dt2 / (dt1 + dt2)

    
    --weight conditions
    if abs(p1length - p0length) < 0.0001 then 
        weight0 = 0
    end
    if abs(p3length - p2length) < 0.0001 then
        weight1 = 0
    end
    if abs(p2length - p1length) < 0.0001 and abs(p3length - p2length) > 0.0001 then
        weight0 = 0
    end
    if abs(p2length - p1length) < 0.0001 and abs(p1length - p0length) > 0.0001 then
        weight1 = 0
    end
    if abs(p2length - p1length) < 0.03 then
        weight0 = weight0 * 0.03
        weight1 = weight1 * 0.03
    end


    local m0 = ((p2 - p0) * weight0) 
    local m1 = ((p3 - p1) * weight1) 

    return m0, m1

end

local function HermiteInterpolator(t, p0, p1, m0, m1)
    local t2 = t * t 
    local t3 = t2 * t

  
    return (2 * t3 - 3 * t2 + 1) * p0 + (t3 - 2 * t2 + t) * m0 +
           (-2 * t3 + 3 * t2) * p1 + (t3 - t2) * m1
end


local cachedt02, cachedt12 = nil, nil
local cachedprev2, cachednext2 = nil, nil
local ppprev, ppp1, ppp2, ppp3 = nil, nil, nil, nil
local framestabla2 = {}

local function HermiteEasing(frames, points, t)
    local n = #points
    local fn = #frames

    if n < 2 then
        table.insert(points, points[1])
    end

    local scaledT
    local index
    local localT
    local firstFrame = frames[1]
    local lastFrame = frames[fn]

    local m0, m1 = nil, nil

    scaledT = allFrames_actualFrame

    index = 0
    for i = 1, fn - 1 do
        if scaledT >= frames[i] and scaledT <= frames[i + 1] then
            index = i  
            firstFrame = frames[i]
            lastFrame = frames[i + 1]
            break
        end
    end


    if allFrames_actualFrame < frames[1] then
        localT = 0
        index = 0
    elseif allFrames_actualFrame > frames[fn] then
        localT = 1
        index = fn-1
    else
        localT = (allFrames_actualFrame - firstFrame) / (lastFrame - firstFrame)
        index = index - 1
    end

    localT = max(0, min(1, localT))

    
    --// FRAMES
    framestabla2[1] = frames[max(index, 1)]
    framestabla2[2] = frames[max(index + 1, 1)]
    framestabla2[3] = frames[min(index + 2, fn)]
    framestabla2[4] = frames[min(index + 3, fn)]
    --// POINTS
    ppprev = points[max(index, 1)]
    ppp1 = points[max(index + 1, 1)]
    ppp2 = points[min(index + 2, n)]
    ppp3 = points[min(index + 3, n)]

    ppp2 = AdjustVectorOrientation(ppp1, ppp2)
    ppp3 = AdjustVectorOrientation(ppp2, ppp3)



    if cachedprev2 == ppp1 and cachednext2 == ppp2 then
        m0 = cachedt02
        m1 = cachedt12
    else
        m0, m1 = HermiteTangentsCalculator(ppprev, ppp1, ppp2, ppp3, framestabla2)
    end

    cachedprev2 = ppp1
    cachednext2 = ppp2
    cachedt02 = m0
    cachedt12 = m1

    local result = HermiteInterpolator(localT, ppp1, ppp2, m0, m1)

    return result
end


function SMH.LerpLinearVector(s, e, p)

    local result

    if SMH.GLOBAL_InterpolationMode == 1 then
        linealSwitch = true
    elseif SMH.GLOBAL_InterpolationMode == 2 then
        linealSwitch = false
    end

    if linealSwitch then
        result = LinearEasingVector(s, e, p)
    else
        result = HermiteEasing(s, e, p)
    end

    return result

end


function SMH.LerpLinear(s, e, p)

    local result

    if SMH.GLOBAL_InterpolationMode == 1 then
        linealSwitch = true
    elseif SMH.GLOBAL_InterpolationMode == 2 then
        linealSwitch = false
    end
    
    if linealSwitch then
        result = LinearEasingNum(s, e, p)
    else
        result = HermiteEasing(s, e, p)
    end

    return result

end