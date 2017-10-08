using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CreateGrid : MonoBehaviour {

    //暂且为正方形吧
    public int terrainSize = 15;
    public int complexity=15;
    public Material terrainMat;
    public Material grassFromGroundMat;

    void Start()
    {
        CreateMesh();
    }

    void CreateMesh()
    {
        List<Vector3> verts = new List<Vector3>();
        List<Vector2> uvs = new List<Vector2>();
        List<int> tris = new List<int>();
        float stepSize = terrainSize / ((float)complexity);
        float halfSize = terrainSize * 0.5f;
        int vertsPerRow = complexity + 1;
        for (int i = 0; i < vertsPerRow; i++)
        {
            for (int j = 0; j < vertsPerRow; j++)
            {
                verts.Add(new Vector3(j*stepSize-halfSize, 0 , halfSize-i*stepSize));
                uvs.Add(new Vector2(j /((float)complexity), i /((float)complexity)) );

                if (i == complexity || j == complexity)
                    continue;

                tris.Add(vertsPerRow * i + j);
                tris.Add(vertsPerRow * i + j + 1);
                tris.Add(vertsPerRow * (i +1) + j);
                tris.Add(vertsPerRow * (i + 1) + j );
                tris.Add(vertsPerRow * i + j+1);
                tris.Add(vertsPerRow * (i + 1) + j+1);
            }
        }
            
        GameObject plane = new GameObject("groundPlane");
        plane.AddComponent<MeshFilter>();
        MeshRenderer renderer = plane.AddComponent<MeshRenderer>();
        renderer.sharedMaterial = terrainMat;

        Mesh groundMesh = new Mesh();
        groundMesh.vertices = verts.ToArray(); 
        groundMesh.uv = uvs.ToArray();
        groundMesh.triangles = tris.ToArray();
        groundMesh.RecalculateNormals(); 
        plane.GetComponent<MeshFilter>().mesh = groundMesh;

        GameObject grass=new GameObject("grassFromGround");
        MeshFilter grassMeshFilter= grass.AddComponent<MeshFilter>();
        MeshRenderer grassRenderer = grass.AddComponent<MeshRenderer>();
        grassRenderer.sharedMaterial = grassFromGroundMat;
        //因为不会再修改mesh，所以共用一个mesh作为src我觉得ok
        grassMeshFilter.mesh=groundMesh;
    }

}
