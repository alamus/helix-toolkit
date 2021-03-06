#ifndef POINTS_FX
#define POINTS_FX

#include "Common.fx"
#include "DataStructs.fx"

float4 vPointParams = float4(4, 4, 0, 0);
float4 vPointColor = float4(1, 1, 1, 1);

void makeQuad(out float4 points[4], in float4 posA, in float w, in float h)
{
    // Bring A and B in window space
    float2 Aw = projToWindow(posA);
    float w2 = w * 0.5;
    float h2 = h * 0.5;

    // Compute the corners of the ribbon in window space
    float2 A1w = float2(Aw.x + w2, Aw.y + h2);
    float2 A2w = float2(Aw.x - w2, Aw.y + h2);
    float2 B1w = float2(Aw.x - w2, Aw.y - h2);
    float2 B2w = float2(Aw.x + w2, Aw.y - h2);

    // bring back corners in projection frame
    points[0] = windowToProj(A1w, posA.z, posA.w);
    points[1] = windowToProj(A2w, posA.z, posA.w);
    points[2] = windowToProj(B2w, posA.z, posA.w);
    points[3] = windowToProj(B1w, posA.z, posA.w);
}

//--------------------------------------------------------------------------------------
// POINTS SHADER
//-------------------------------------------------------------------------------------
GSInputPS VShaderPoints(VSInputPS input)
{
    GSInputPS output = (GSInputPS)0;	
    if (bHasInstances)
    {
        matrix mInstance =
        {
            input.mr0.x, input.mr1.x, input.mr2.x, input.mr3.x, // row 1
			input.mr0.y, input.mr1.y, input.mr2.y, input.mr3.y, // row 2
			input.mr0.z, input.mr1.z, input.mr2.z, input.mr3.z, // row 3
			input.mr0.w, input.mr1.w, input.mr2.w, input.mr3.w, // row 4
        };
        input.p = mul(mInstance, input.p);
    }

    output.p = input.p;

    //set position into clip space	
    output.p = mul( output.p, mWorld );		
    output.p = mul( output.p, mView );    
    output.p = mul( output.p, mProjection );	
    output.c = input.c * vPointColor;
    return output;
}

[maxvertexcount(4)]
void GShaderPoints(point GSInputPS input[1], inout TriangleStream<PSInputPS> outStream)
{
    PSInputPS output = (PSInputPS)0;
        
    float4 spriteCorners[4];
    makeQuad(spriteCorners, input[0].p, vPointParams.x, vPointParams.y);

    output.p = spriteCorners[0];
    output.c = input[0].c;
    output.t[0] = +1;
    output.t[1] = +1;
    output.t[2] = 1;	
    outStream.Append( output );
    
    output.p = spriteCorners[1];
    output.c = input[0].c;
    output.t[0] = +1;
    output.t[1] = -1;
    output.t[2] = 1;	
    outStream.Append( output );
 
    output.p = spriteCorners[2];
    output.c = input[0].c;
    output.t[0] = -1;
    output.t[1] = +1;
    output.t[2] = 1;	
    outStream.Append( output );
    
    output.p = spriteCorners[3];
    output.c = input[0].c;
    output.t[0] = -1;
    output.t[1] = -1;
    output.t[2] = 1;	
    outStream.Append( output );
    
    outStream.RestartStrip();
}

float4 PShaderPoints( PSInputPS input ) : SV_Target
{
    if (vPointParams[2] == 1)
    {
        float len = length(input.t);
        if (len > 1.4142) discard;
    }
    else if (vPointParams[2] == 2)
    {
        float arrowScale = 1 / (vPointParams[3] + (input.t[2] > 0.9)*(-input.t[2] + 1) * 10);
        float alpha = min(abs(input.t[0]), abs(input.t[1]));
        float dist = arrowScale * alpha;
        alpha = exp2(-4 * dist*dist*dist*dist);
        if (alpha < 0.1) discard;
    }

    return input.c;
}
#endif